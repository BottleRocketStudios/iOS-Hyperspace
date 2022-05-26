#  Handling Common Networking Scenarios

## Happy Path

The intent behind the move to structured concurrency in Hyperspace is that if the call to `execute` a given `Request<Response>` does not `throw`, you should always be handed back a `Response` when execution completes. For example, the happy path scenario, consider the following:

```swift
do {
    let getUserRequest = Request<User>.getUser(withID: 1)
    let user = try await backendService.execute(request: getUserRequest)
    presentAlert(titled: "Success", message: "Fetched user with name: \(user.name)")

} catch { ... }
```

If the call to `backendService.execute` does not `throw`, you will receive a `User` object after `await`. Any error, regardless of when in the networking process it occurs, will cause `execute` to throw. This means that, depending on the level of error handling required, multiple different types of errors may need to be handled.


## Handling an Error (ex: No Connection, Cancellation)

The first way a network request can go wrong is client-side. `URLSession` often represents these issues by throwing a [`URLError`](https://developer.apple.com/documentation/foundation/urlerror) (but this is not, and can not be, guaranteed). For example, if trying to inappropriately access an HTTP resource, you may be thrown a `URLError` with the `appTransportSecurityRequiresSecureConnection` code. Alternatively, you may be thrown a `URLError` with the `notConnectedToInternet` code when attempting to access a remote resource with no active internet connection.

```swift
do {
    let user = try await backendService.execute(request: request)
    // Use `user`

} catch let urlError as URLError {
    switch urlError.code {
    case .appTransportSecurityRequiresSecureConnection: // App Transport Security requires the use of a secure connection
    case .notConnectedToInternet: // The device is not currently connected to the internet
    default: // Something else went wrong
    }
}
```


## Handling a 3xx / 4xx / 5xx

The `URLSession` type draws a strict line between transport errors (like a lack of connection) and errors returned by the server. This is because the interpretation of a server-side error is server specific, and can not be effectively handled in a generic fashion by `URLSession`. Essentially, any server response with a status code of 200-299 will be considered as success (represented as a `TransportSuccess`), otherwise a failure (represented as a thrown `TransportFailure`). Building upon the previous example, you'd need to additionally handle catching a `TransportFailure`

```swift
do {
    let user = try await backendService.execute(request: request)
    // Use `user`

} catch let urlError as URLError {
    ...
} catch let transportFailure as TransportFailure {
    let failedRequest = transportFailure.request // The request to the server that failed
    let failedResponse = transportFailure.response // The response from the server

    switch transportFailure.kind {
    case .clientError(let clientError): // 400 - 499 Status Code
    case .serverError(let serverError): // 500 - 509 Status Code
    case .redirection: // 300 - 399 Status Code
    case .unknown: // A unknown failure occurred
    }
}
```


## Handling a Transformation Failure

Assuming a `TransportSuccess` object has been received, there is one final part to the `execute` process - transformation. Often occurring through the `Decodable` machinery, this is the the process of converting the received `TransportSuccess` into the designated `Response` type. Depending on the specifics of the transformation there are several different types of `Error` that can be thrown here, but usually errors from this part of the process will be thrown `DecodingError`s.

```swift
do {
    let user = try await backendService.execute(request: request)
    // Use `user`

} catch let urlError as URLError {
    ...
} catch let transportFailure as TransportFailure {
    ...
} catch let decodingError as DecodingError {
    // An error occurred decoding `transportSuccess.data` into `Response`
}
```


## Automatic Recovery

As with previous versions of Hyperspace, the `RecoveryStrategy` protocol can still be utilized to perform automatic, repeated recoveries on `Request`s. Take a re-authorization recovery strategy for example, where a 401 Unauthorized `TransportFailure` response should automatically trigger a token refresh and retry. A `RecoveryStrategy` that detects these responses and automatically performs the refresh and retry can be set on the `BackendServicing` object, automatically running on every failed request executed by the `BackendServicing` object.

```swift
struct AuthorizationRecoveryStrategy: RecoveryStrategy {

    func attemptRecovery<R>(from error: Error, executing request: Request<R>) async -> RecoveryDisposition<Request<R>> {
        // If the response is not a 401 Unauthorized, report back that we won't even make an attempt to recover. This signals to the `BackendServicing` object to check if the next strategy in it's `recoveryStrategies` property can attempt recovery.
        guard let transportFailure = error as? TransportFailure,
              case let .clientError(clientError) = transportFailure.kind, clientError == .unauthorized else { return .noAttemptMade }

        // In this example, our `getRefreshedToken()` call can not throw, but keep in mind the `error` returned here does not have to be the original error given to the recovery strategy.
        guard let newToken = await getRefreshedToken(), let nextAttempt = request.updatedForNextAttempt() else { return .fail(error) }
        let authenticatedNextAttempt = nextAttempt.authenticated(with: self.requestAuthenticator, using: newToken)

        // This updated request will be automatically executed by the `BackendServicing` object. Its result will be returned as the result of the original request.
        return .retry(authenticatedNextAttempt)
    }
}
```


## Interpreting a non-Success as a success

In the inverse situation, it can also be useful to be able to consider a traditional failure response as a success. For example, consider a situation in which you need to identify the redirect target URL for a given `Request`, but can not actually follow the redirect. Disallowing HTTP redirects is as simple as implementing a method on `URLSessionTaskDelegate`. But once this happens you're call to `execute` will, by default, return a `TransportFailure` containing the 3XX response. By utilizing, the `quickRecoveryTransformer` property, this `TransportFailure` can be quickly treated as a `TransportSuccess`.

```swift
public extension Request {

    func handlingRedirectsAsSuccess() -> Request<Response> {
        var copy = self
        copy.recoveryTransformer = { failure in
            guard failure.response.status.isRedirection else { return nil }
            return TransportSuccess(response: response)
        }

        return copy
    }
}
```

The execution of `quickRecoveryTransformer` on these redirect responses will allow the success transformation response to continue - allowing the end user to utilize the various properties of the `TransportSuccess` to identify the information needed (ex: `transportSuccess.response.headers?[.location]`) to identify the redirect target URL.


## Additional Success Validation

There may be times when an API returns a 200 status code that isn't necessarily indicative that the request succeeded - for example:

200 OK

{
    "code": 500,
    "message": "Internal server error"
}

Using the default behaviors in Hyperspace with a `Codable` model object, this would likely throw a `DecodingError` of some form. In reality though, the `DecodingError` is masking the real issue - the real issue lies with the request or the server's response to that request, not the app's attempt to parse the apparently successful response.

The simplest way to ensure that the proper error is thrown in these situations, the `request.successValidator` can be customized. This is a closure that is executed on receipt of a `TransportSuccess` and allow the caller to customize the behavior by optionally throwing an `Error`.

```swift
var request = Request<User>.getUser(withID: 1)
request.successValidator = { transportSuccess in
    if let data = transportSuccess.body, let serverError = try? JSONDecoder().decode(ServerError.self, from: data) {
        throw serverError
    }
}
```

When this `request` is executed, any `TransportSuccess` object received in response will be run through the `successValidator` closure. If this closure subsequently `throws`, that error will be thrown from the original call to `execute` the request. Otherwise, the transformation process will continue as normal.


## Transforming an Error

In situations like the above though, it it sometimes desirable to not have to run a closure every response (success or not), but maintain the ability to automatically transform the `Error` thrown by the execution of the request.

In these situations, you can use the `.throwing { ... }` function on `Request`.

```swift
let request = Request<User>(url: myURL).throwing { transportSuccess, originalError in
    let serverError = JSONDecoder().decode(ServerError.self, from: transportSuccess.body ?? Data())
    return serverError
}
```

This will have the same net effect as performing additional validation using the `successValidator` property, but this closure will only be run once an error has been encountered.

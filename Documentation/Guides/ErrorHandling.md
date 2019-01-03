### Basic Error Handling

As a general rule, networking is hard. A lot can go wrong in the process of communicating between an application and a backend. One of the goals of Hyperspace is to make the many different failure reasons easy to understand and easy to react to. In this section, we'll describe the steps needed to do the bare minimum to effectively handle errors.

In the vast majority of scenarios, your app will interface with Hyperspace by creating an object that conforms to the `NetworkRequest` protocol and handing it to a `BackendService`. At this point, the `BackendService` will unwrap the underlying `URLRequest` and forward it on to an object called a `NetworkService`, which in turn uses a `NetworkSession` to execute the request itself. Each of the layers in this process play a distinct role in the error handling process.

After the request has been handed off to the `NetworkSession` (on iOS, this will most likely be a `URLSession` object) there are a large number of states, both successful and failed, that can result. The job of the `NetworkService` is to convert the data returned by the `NetworkSession` into a more concise cause of the problem:

```swift
(data: Data, response: URLResponse, error: Error) -> Result<NetworkServiceSuccess, NetworkServiceFailure>
```

In both cases, this `Result` will be passed back on to the `BackendService` for further processing. In the event of a success, a `NetworkServiceSuccess` object will be returned. This object is exactly what it sounds like - it contains the `Data` returned as well as the `HTTP.Response`.

The `NetworkServiceFailure` is very similar - it contains a `NetworkServiceError` as well as the raw `HTTP.Response` (where applicable - if the error occurs before interaction with a backend, this response will be `nil`. This can happen for instance, if no internet connection is available). If you are looking for the root cause of the failure, this can be found in the `NetworkServiceError` object, which has cases for:
- Redirection
- Client Errors (400-499 status codes are individually mapped, eg. unauthorized, forbidden, bad request)
- Server Errors (500+ status codes are individually mapped, eg. bad gateway, internal server error)
- No Data
- No Connection
- Timeout
- Cancellation
In the vast majority of time, the `NetworkService` is the object that does the majority of the error handling. But during development, there are a small subset of errors that can occur when transforming a `NetworkServiceSuccess` into a usable object. This is the responsibility of the `BackendService`.

The `BackendService` responsibilities can be summarized as follows:

```swift
(result: Result<NetworkServiceSuccess, NetworkServiceFailure>) -> Result<ResponseType, ErrorType>
```

In the case the result contains a `NetworkServiceFailure`, the failure will be used to initialize an `ErrorType` object. This type is set by the application when creating the `NetworkRequest`. If you are using `AnyNetworkRequest<T>`, this `ErrorType` will be set as an `AnyError` object. If you are using a custom `NetworkRequest`, you can specify this `ErrorType` associated type to be anything that conforms to `Swift.Error & NetworkServiceFailureInitializable`. In both cases, this error is then returned as a `Result.failure`.

In the case of a `NetworkServiceSuccess`, the success object is forwarded on to `NetworkRequest.transformSuccess(_:)`. The result of this transform (`Result<ResponseType, ErrorType>`) is then returned to the original caller.

### Custom Error Handling

In many cases, simply wrapped the underlying error in an `AnyError` and returning that is not an efficient form of error handling. It requires every caller of the API to then unwrap the `AnyError` to find the underlying cause. In cases where more sophisticated error handling is required, a custom `NetworkRequest` can be used.

In this case, the `ErrorType` associated type must be a type conforming to `NetworkServiceFailureInitializable`. If the `NetworkService` identifies a failure coming from the network, it will pass the `NetworkServiceFailure` on to your custom initializer. This gives your error object direct access to both the `Data` (if it exists) and the `HTTP.Response` (if it exists) coming from the server. This allows you to do things like parsing the complete error message returned by the server, and that parsing can vary based of `HTTP.Response.statusCode`. This allows you to have a much more fluent error handling scheme, and communicate more pertinent information back to the caller.

While most APIs return proper HTTP status codes with their error messages, there are some that don't. In the case that a successful status code is returned, but the `Data` contained in the response does not represent the desired model object (as it would in a true success), `NetworkRequest.transformSuccess(_:)` would ordinarily throw a failure. If you are dealing with strictly `Decodable` types, conforming your error type to `DecodingFailureInitializable` will give you another chance to refine the error handling. Hyperspace provides a default `transformSuccess(_:)` implementation that handles any `Decodable` type when your error type conforms to this protocol. If, in the process of decoding your response from `Data`, a `DecodingError` is thrown, the results will be passed on to your error through the function:

```swift
init(decodingError: DecodingError, decoding: Decodable.Type, data: Data)
```

This initializer will allow you to inspect the problem with the decode (this will happen frequently during development), as well as provide you with the raw data and the type that failed to decode. In some cases, this `Data` may be representative of an error and can then be decoded before being returned to the caller.

### Error Recovery

There are times when certain errors are not fatal, and a retry at some point in the future would prove successful. `BackendService` provides support for this through two protocols. `Recoverable` is a protocol which outlines the metrics required to determine when it is appropriate to recover from a failure and retry a request. It records the number of attempts made, as well as the number allowed and is used by the `RequestRecoveryStrategy` to determine if the failure can be recovered from. This strategy, has one requirement:

```swift
func handleRecoveryAttempt<T: Recoverable & NetworkRequest>(for request: T, withError error: T.ErrorType, completion: @escaping (RecoveryDisposition<T>) -> Void)
```

The implementation of this function should contain the logic to determine if the cause of failure for a particular request is fatal. For example, you may wish to automatically retry a request in which you receive a 401 Unauthorized response:

```swift
struct AuthorizationRecoveryStrategy: RequestRecoveryStrategy {
        func handleRecoveryAttempt<T: NetworkRequest & Recoverable>(for request: T, withError error: T.ErrorType, completion: @escaping (RecoveryDisposition<T>) -> Void) {
            guard case let .clientError(clientError) = error.networkServiceError, clientError == .unauthorized, let nextAttempt = request.updatedForNextAttempt() else { return completion(.fail) }

            let newRequest = nextAttempt.addingHeaders([.authorization: HTTP.HeaderValue(rawValue: "some_access_token")])
            completion(.retry(newRequest))
        }
    }
```

This strategy checks to ensure that the error is a 401 Unauthorized, and that the request itself is retry-able, before adding/updating the appropriate HTTP headers. At this point, the new request will be retried as dictated by `RecoveryDisposition.retry(newRequest)`. If this updated request fails once more, it will be run through the `RequestRecoveryStrategy` until one of two conditions are true: a) the maximum number of attempts has been taken, b) the error is not a 401 Unauthorized.

All of these recovery attempts are transparent to the caller - the completion block passed in to the `BackendService` initially will only be executed when either the request returns successfully, or the strategy dictates `RecoveryDisposition.fail`.

Note that in order to utilize this transparent recovery, your custom request type must conform to `Recoverable` and you must use `BackendService.execute(recoverable:_:)`.

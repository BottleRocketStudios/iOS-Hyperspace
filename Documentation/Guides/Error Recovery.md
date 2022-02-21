# Error Recovery

When it comes to networking, errors are a given. It is very important that a networking framework give the client total control on determining which errors are recoverable and which are fatal, and a path from which to recover from non-fatal errors. Hyperspace provides two methods to recover from errors in the network transport process, described below.  

## Quick Recovery

Sometimes it is necessary to consider a status code that typically indicates a failure as a success. For example, some auth implementations return a redirect and ask the user to then manually extract information from the headers of that redirect response. In this case, it is very easy to tell Hyperspace to consider a 3XX response a success:

```swift
func handlingRedirectsAsSuccess() -> Request<Response, Error> {
       var copy = self
       copy.recoveryTransformer = { failure in
           guard let response = failure.response, response.status.isRedirection else { return nil }
           return TransportSuccess(response: response)
       }

       return copy
   }
```

```swift
let request = Request<HTTP.Response, MyError> = .init(method: .get, url: url, headers: [.accept: .applicationJSON]) { transportSuccess in
           return .success(transportSuccess.response)
       }.handlingRedirectsAsSuccess()
```

Instead of going through the `TransportFailureRepresentable` machinery as usual, the presence of a `Request.recoveryTransfer` that returns a non-nil `TransportSuccess` object allows the request to be considered successful giving the `Request.successTransformer` access to the raw 3XX `HTTP.Response`.

The `recoveryTransformer` is run before any of the `RecoveryStrategy`, meaning it is the quickest way to convert a "failure" into a "success". It is a non-optional property that defaults to simply returning `nil`.

## Recovery Strategies

There are times when certain errors received are not fatal, and a retry at some point in the future would prove successful. `BackendService` provides support for this through two protocols. `Recoverable` is a protocol which outlines the metrics required to determine when it is appropriate to recover from a failure and retry a request (and `Request` conforms to this protocol). It records the number of attempts made, as well as the number allowed and is used by the `RecoveryStrategy` to determine if the failure can be recovered from. This strategy, has two requirements:

```swift
func canAttemptRecovery<R, E>(from error: E, for request: Request<R, E>) -> Bool

func attemptRecovery<R, E>(for request: Request<R, E>, with error: E, completion: @escaping (RecoveryDisposition<Request<R, E>>) -> Void)
```

The first function indicates whether or not an attempt at recovery can even be made (for example, a re-authentication recovery strategy isn't going to help in the case of 500 Internal Server Error, but it may help in the cause of a 401 Unauthorized), and the second is the implementation of the attempt at recovery. The implementation of this second function should contain the logic to determine if the cause of failure for a particular request is fatal, for example refreshing the access token before retrying the request:

```swift
public func canAttemptRecovery<R, E>(from error: E, for request: Request<R, E>) -> Bool where E: TransportFailureRepresentable {
    guard case let .clientError(clientError) = error.transportError?.code, clientError == .unauthorized else { return false }
    return true
}

public func attemptRecovery<R, E>(for request: Request<R, E>, with error: E, completion: @escaping (RecoveryDisposition<Request<R, E>>) -> Void)  where E: TransportFailureRepresentable {
    guard canAttemptRecovery(from: error, for: request) else { return completion(.fail) }

    let newToken = // get a new access token

    guard let nextAttempt = request.updatedForNextAttempt() else { return completion(.fail) }
    let authenticatedNextAttempt = nextAttempt.authenticated(with: self.requestAuthenticator, using: newToken)
    completion(.retry(authenticatedNextAttempt))
}
```

This strategy checks to ensure that the error is a 401 Unauthorized, before retrieving a new token and adding/updating the appropriate HTTP headers. At this point, the new request will be retried as dictated by `RecoveryDisposition.retry(newRequest)`. If this updated request fails once more, it will be run through the `RecoveryStrategy` until one of two conditions are true:
- the maximum number of attempts has been taken
- the error is not a 401 Unauthorized.

All of these recovery attempts are transparent to the caller - the completion block passed in to the `BackendService` initially will only be executed when either the request returns successfully, or the strategy dictates `RecoveryDisposition.fail`.

In the case that you have multiple ways in which you can attempt recovery, it is recommended to attach them separately to the `BackendService.recoveryStrategies` property. In the case you have multiple strategies, each will be queried in order before recovery is attempted. The first strategy that returns `true` from `canAttemptRecovery(from:for:)` will be allowed to attempt the recovery. If that attempt at recovery fails (returns `RecoveryDisposition.fail`), no other strategies will be attemped. If however, the recovery attempt succeeds (returns `RecoveryDisposition.retry`), but this retried request fails again - the entire set of recovery strategies will be checked again for their ability to recover.

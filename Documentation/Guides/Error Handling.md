### Basic Error Handling

As a general rule, networking is hard. A lot can go wrong in the process of communicating between an application and a backend. One of the goals of Hyperspace is to make the many different failure reasons easy to understand and easy to react to. In this section, we'll describe the steps needed to do the bare minimum to effectively handle errors.

In the vast majority of scenarios, your app will interface with Hyperspace by creating a `Request` struct and handing it to a `BackendService`. At this point, the `BackendService` will unwrap the underlying `URLRequest` and forward it on to an object called a `TransportService`, which in turn uses a `NetworkSession` to execute the request itself. Each of the layers in this process play a distinct role in the error handling process.

After the request has been handed off to the `TransportSession` (on iOS, this will most likely be a `URLSession` object) there are a large number of states, both successful and failed, that can result. The job of the `TransportService` is to convert the data returned by the `TransportSession` into a more concise cause of the problem:

```swift
(data: Data, response: URLResponse, error: Error) -> Result<TransportSuccess, TransportFailure>
```

In both cases, this `Result` will be passed back on to the `BackendService` for further processing. In the event of a success, a `TransportSuccess` object will be returned. This object is exactly what it sounds like - it contains the `Data` returned as well as the `HTTP.Response`.

The `TransportFailure` is very similar - it contains a `TransportError` as well as the raw `HTTP.Response` (where applicable - if the error occurs before interaction with a backend, this response will be `nil`. This can happen for instance, if no internet connection is available). If you are looking for the root cause of the failure, this can be found in the `TransportError` object, which has cases for:
- Redirection
- Client Errors (400-499 status codes are individually mapped, eg. unauthorized, forbidden, bad request)
- Server Errors (500+ status codes are individually mapped, eg. bad gateway, internal server error)
- No Data
- No Connection
- Timeout
- Cancellation
In the vast majority of time, the `TransportService` is the object that does the majority of the error handling. But during development, there are a small subset of errors that can occur when transforming a `TransportSuccess` into a usable object. This is the responsibility of the `BackendService`.

The `BackendService` responsibilities can be summarized as follows:

```swift
(result: Result<TransportSuccess, TransportFailure>) -> Result<ResponseType, ErrorType>
```

In the case the result contains a `TransportFailure`, the failure will be used to initialize an `Error` object. This type is set by the application when creating the `Request`. This `Error` object is specified at the time of creation of the `Request`, and can be anything that conforms to `Swift.Error & TransportFailureRepresentable`. In both cases, this error is then returned as a `Result.failure`.

In the case of a `TransportSuccess`, the success object is forwarded on to `Request.transformSuccess(_:)`. The result of this transform (`Result<Response, Error>`) is then returned to the original caller.


### Custom Error Handling

In many cases, simply wrapped the underlying error in an `AnyError` and returning that is not an efficient form of error handling. It requires every caller of the API to then unwrap the `AnyError` to find the underlying cause. In cases where more sophisticated error handling is required, a custom `Request` can be used which defines a custom `Error` type.

In this case, the `Error` generic type must be a type conforming to `TransportFailureRepresentable`. If the `TransportService` identifies a failure coming from the network, it will pass the `TransportFailure` on to your custom initializer. This gives your error object direct access to both the `Data` (if it exists) and the `HTTP.Response` (if it exists) coming from the server. This allows you to do things like parsing the complete error message returned by the server, and that parsing can vary based of `HTTP.Response.statusCode`. This allows you to have a much more fluent error handling scheme, and communicate more pertinent information back to the caller.

While most APIs return proper HTTP status codes with their error messages, there are some that don't. In the case that a successful status code is returned, but the `Data` contained in the response does not represent the desired model object (as it would in a true success), `Request.transformSuccess(_:)` would ordinarily throw a failure. If you are dealing with strictly `Decodable` types, conforming your error type to `DecodingFailureRepresentable` will give you another chance to refine the error handling. Hyperspace provides a default `transformSuccess(_:)` implementation that handles any `Decodable` type when your error type conforms to this protocol. If, in the process of decoding your response from `Data`, a `DecodingError` is thrown, the results will be passed on to your error through the function:

```swift
init(decodingFailure: DecodingFailure)
```

This initializer will allow you to inspect the problem with the decode (this will happen frequently during development), as well as provide you with the raw data and the type that failed to decode. In some cases, this `Data` may be representative of an error and can then be decoded before being returned to the caller.

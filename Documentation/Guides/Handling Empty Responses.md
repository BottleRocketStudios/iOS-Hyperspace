### Handling Empty Responses

Handling an empty response from your API, such as a DELETE request that returns a `204 No Content`, seems like a very straightforward task. In reality, there is a huge amount of complexity in handling the many different ways that APIs can choose to communicate 'the request was successful, there is nothing else to return'. REST API guidelines would dictate that in these situations no body should be sent back but some servers may opt to send a confirmation that the request succeeded.

```json
{
    "returnCode": 204,
    "message" : "Successful"
}
```

To make matters worse, sometimes servers return a `200 OK` status code and send error information in the response body. This forces the consumer of the API to check errors when essentially it seems there should be none.

```json
{
    "returnCode": 500,
    "message" : "Some failure here"
}
```

Fortunately, Hyperspace makes the variable decoding and validation of `EmptyResponse` incredibly flexible and powerful (if you need to deal with these variable return codes with non-`EmptyResponse` objects, check out [`Documentation/Guides/Custom Decoding.md`](../Guides/Custom%20Decoding.md).). Unlike many of Hyperspace `Request`s, an `EmptyResponse` request is created using the following API:

```swift
    static func withEmptyResponse(method: HTTP.Method,
                                  url: URL,
                                  headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = nil,
                                  body: HTTP.Body? = nil,
                                  cachePolicy: URLRequest.CachePolicy = RequestDefaults.defaultCachePolicy,
                                  timeout: TimeInterval = RequestDefaults.defaultTimeout,
                                  emptyDecodingStrategy: EmptyDecodingStrategy = .default) -> Request {
    }
```

Every flexibility afforded to a standard `Request` is available here, and although using a `Request.Error` that conforms to `DecodingFailureRepresentable` is highly recommended, it is possible to create a `Request<EmptyResponse, _>` for any error in which you can define a transform to convert a `DecodingFailure` to your custom `Error` type.

The addition here that makes decoding an `EmptyResponse` so flexible is the `EmptyDecodingStrategy`. This is the object that governs the transformation from the `TransportSuccess` into a `Result<EmptyResponse, Error>`. If you need to implement custom validation logic (perhaps to ensure the `returnCode` in the response matches the HTTP status code - you'll want to extend `EmptyDecodingStrategy`). To cover the vast majority of use cases though, Hyperspace ships with two `EmptyDecodingStrategy` of its own:

- `default` : If the handler receives a `TransportSuccess`, this will return a `.success(EmptyResponse())`, regardless of the actual contents of the HTTP response.
- `validatedEmpty` : If the handler receives a `TransportSuccess`, this strategy will check to ensure the HTTP response body is either `nil` or `isEmpty` before returning a `.success(EmptyResponse())`. In the case that the body fails either of those checks, a `DecodingFailure.invalidEmptyResponse` is returned, along with the `HTTP.Response` received from the request.

### Extending EmptyDecodingStrategy

What about the special case where some kind of custom validation of "empty" response is needed before the request can be deemed successful? `EmptyDecodingStrategy` has you covered here as well. For example, let's assume that we are going to receive a response that looks like the following: 

```json
{
    "returnCode": 500,
    "message" : "Some failure message here"
}
```

How would we go about validating that the `returnCode` indicates a successful response before we return a "success"?

```swift
enum MyError: DecodingFailureRepresentable {
    case networkResponseCodeMismatch

    var failureResponse: HTTP.Response? { return ... }
    var transportError: TransportError? { return ... }

    init(transportFailure: TransportFailure) {
        ...
    }

    init(decodingFailure: DecodingFailure) {
         ...
    }
}

struct NetworkResponse: Decodable {
    let returnCode: Int
    let message: String
}

extension Request.EmptyDecodingStrategy where Response == EmptyResponse, Error == MyError {

    static var validatingNetworkResponse: Request.EmptyDecodingStrategy {
        return Request.EmptyDecodingStrategy { decodingFailureTransformer -> Request.Transformer in
            return { transportSuccess in

                do {
                    let networkResponse =  try JSONDecoder().decode(NetworkResponse.self, from: transportSuccess.body ?? Data())
                    guard networkResponse.returnCode == 200 else {
                        return .failure(MyError.networkResponseCodeMismatch)

                        // If you don't have a custom error type, you can also return some kind of `TransportFailure` or just simply `DecodingFailure.invalidEmptyResponse` here.
                        //return .failure(TransportFailure(...))
                        //return .failure(decodingFailureTransformer(.invalidEmptyResponse(transportSuccess.response)))
                    }

                    return .success(EmptyResponse())

                } catch let decodingError as DecodingError {
                    let context = DecodingFailure.Context(decodingError: decodingError, failingType: NetworkResponse.self, response: transportSuccess.response)
                    return .failure(decodingFailureTransformer(.decodingError(context)))

                } catch {
                    let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: error.localizedDescription))
                    let context = DecodingFailure.Context(decodingError: decodingError, failingType: NetworkResponse.self, response: transportSuccess.response)
                    return .failure(decodingFailureTransformer(.decodingError(context)))
                }
            }
        }
    }
}
```

Using this brand new strategy is as easy as you would use any of the pre-existing `EmptyDecodingStrategy`:

```swift
extension Request where Response == EmptyResponse, Error == MyError {

    static func delete(withID id: Int) -> Request<EmptyResponse, MyError> {
        return Request.withEmptyResponse(method: .delete, url: URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!, emptyDecodingStrategy: .validatingNetworkResponse)
    }
}
```

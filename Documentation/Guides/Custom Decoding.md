### Custom Decoding with Request

Since the introduction of `Codable`, parsing alternate representations of model objects has become drastically simpler. Hyperspace is no different - it heavily leans on `Codable` to make parsing network responses painless. By default, Hyperspace will opt to use the default instance of `JSONDecoder`. This object expects it's `Date`s represented as a time interval since 1970, it's data represented as a base-64 encoded `String` and will `throw` if encountering any non-conforming floats.

If the objects you are trying to fetch with a `Request` rely on a non-default setting of these properties, you can still use the default `Codable` extensions that are built into Hyperspace - you don't have to rewrite anything.

When using `Request<Response: Decodable, AnyError>`, there are two main initializers:

```swift
public init(method: HTTP.Method, url: URL, headers: [HTTP.HeaderKey: HTTP.HeaderValue]?, body: HTTP.Body?,
    cachePolicy: URLRequest.CachePolicy, timeout: TimeInterval, dataTransformer: @escaping (TransportSuccess) -> Result<Response, Error>)

public init(method: HTTP.Method, url: URL, headers: [HTTP.HeaderKey: HTTP.HeaderValue]?, body: HTTP.Body?,
    cachePolicy: URLRequest.CachePolicy, timeout: TimeInterval, decoder: JSONDecoder)
```

The first of these initializers allows you to completely customize the data transformation block to your liking. This is the default initializer that is used with all types. The second initializer is an option only when `Response` is `Decodable`. At this point you simply pass in the `JSONDecoder` instance you need, and Hyperspace will use it to do the rest.

In addition,`Request` contains more options when you are working with a `Response: Decodable`:

```swift
public static func successTransformer(for decoder: JSONDecoder) -> Transformer    
public static func successTransformer(for decoder: JSONDecoder, errorTransformer: @escaping DecodingFailureTransformer) -> Transformer {
```

The first of these functions provides a default that can be used for any `Codable` type, as long as your error conforms to `DecodingFailureRepresentable`. But, in the case that your `Error` does not conform, you can use the other function - in which you simply provide a closure to convert a generic error to your type: `(Swift.Error) -> Error`

### Decoding With Containers

It is not uncommon to see JSON resembling below (where the object at 'root_key' is what you're trying to decode):

```
{
    "root_key": {
        "title": "Some Title!"
        "subtitle": "Some subtitle"
    }
}
```

To make this as painless as possible, Hyperspace has built support for `DecodableContainer`s. This is a protocol which contains a single child element (the element you want to decode) - all you have to do is specify the root key in the container's `CodingKeys`. For example:

```swift
struct MockDecodableContainer: DecodableContainer {
    var element: MockObject

    private enum CodingKeys: String, CodingKey {
        case element = "root_key"
    }
}
```

In the above example, the container will decode the `MockObject` type at the "root_key" key in the JSON. We've built support in to Hyperspace for these contains extensively:

In `JSONDecoder`:

```swift
func decode<T, U: DecodableContainer>(_ type: T.Type, from data: Data, with container: U.Type) throws -> T where T == U.ContainedType
```

In `Request`:

```swift
public init<U: DecodableContainer>(method: HTTP.Method, url: URL, headers: [HTTP.HeaderKey: HTTP.HeaderValue]?, body: HTTP.Body?,
    cachePolicy: URLRequest.CachePolicy, timeout: TimeInterval, decoder: JSONDecoder, containerType: U.Type) where U.ContainedType == T
```

This support also exists for creating `HTTP.Body` objects in the form of `EncodableContainer`.

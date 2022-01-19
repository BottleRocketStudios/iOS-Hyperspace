# Hyperspace 3.x-4.0 Migration Guide

This guide has been provided in order to ease the transition of existing applications using Hyperspace 3.x to the latest APIs, as well as to explain the structure of the new and changed functionality.

## Requirements

- iOS 12.0, tvOS 12.0, watchOS 6.0
- Xcode 13.2
- Swift 5.0

## Overview

Hyperspace 4.0 brings some core changes to the API surface of the framework, with the intent to allow a smoother transition to a `async` world in future versions. While many of these changes are source-compatible with Hyperspace 3.x, there a few larger changes that will require adaptation that will be discussed below.

## Breaking Changes

### `struct Request`

Starting in Hyperspace 4.0, the `Request` protocol no longer exists - it has been replaced by `struct Request<Response, Error>`, in order to benefit the flexibility of the framework. Along with this change, the previous generic implementation of the protocol, `AnyRequest`, has been removed.

In order to accomodate the many different ways a `Request` object could be transformed in a `URLRequest` object suitable for transport to a backend, a new property has been added to the `Request` struct - `var urlRequestCreationStrategy: URLRequestCreationStrategy` where the default value will function exactly the same as `AnyRequest` did previously.

While previously the recommended way to create requests for use with Hyperspace was by defining a custom type that conforms to the protocol, it is now recommended to extend the existing `Request` type:

```swift
extension Request {
    static func createPost(_ post: NewPost) -> Request<Post, AnyError> {
        return Request(method: .post, url: URL(string: "https://jsonplaceholder.typicode.com/posts")!, headers: [.contentType: .applicationJSON],
                       body: try? HTTP.Body(post))
    }
}
```

For advanced usages, it is still possible to create unique types for each request by wrapping the framework's `Request` type and create the `Hyperspace.Request` in a computed property:

```swift
struct CreatePostRequest {
    let newPost: NewPost

    var request: Request<Post, AnyError> {
        return Request(method: .post, url: URL(string: "https://jsonplaceholder.typicode.com/posts")!, headers: [.contentType: .applicationJSON],
                       body: try? HTTP.Body(post))
    }
}
```

### `NetworkService` renamed to `TransportService`

Another change is the renaming of the various `Network` related types in the framework to `Transport`. This includes `Transporting` (previously `NetworkServiceProtocol`), `TransportService` (previously `NetworkService`), `TransportResult` (previously `NetworkServiceResult`), `TransportSuccess` (previously `NetworkServiceSuccess`), `TransportFailure` (previously `NetworkServiceFailure`), `TransportFailureRepresentable` (previously `NetworkServiceFailureInitializable`) and `TransportSession` (previously `NetworkSession`). In many instances, deprecated typealiases should exist to ease the transition to the new type name.

### Strongly typed HTTP Headers

In Hyperspace 4.0, the headers property of `Request` is now strongly typed as `public var headers: [HTTP.HeaderKey: HTTP.HeaderValue]?`. Both the key and value are easily extendable, and a wider range of presets are built in to Hyperspace.

### Strongy typed HTTP Body

Along with the changes to the headers, a new type has been introduced in 4.0 which abstracts over the HTTP body. Instead of accepting an arbitrary `Data` object, a new `HTTP.Body` type has been introduced to make common cases (like URL forms and JSON) easier to implement. In addition the `HTTP.Body` now supports adding additional HTTP headers that are automatically applied to any request containing that body.

### Multiple Recovery Strategies

The `BackendService` now supports multiple possible `RecoveryStrategy` objects (previously `RequestRecoveryStrategy`). In the cases where recovery may be applicable, these `RecoveryStrategy` will be queried in order, and the first strategy that is able to attempt a recovery operation will be used. If that recovery attempt then fails, no other strategies will be tried and the request will report a failure result back to the caller.

### Error Handling

There have been several changes made to the core `NetworkService` functionality to allow for more fine grained error handling. These changes include:

- Any time your custom `Error` type is initialized, the raw `HTTP.Response` received by the server will be provided. This will happen both when a transport failure and decoding failure occurs, and gives access to data like the raw http status and response data.
- The given `HTTP.Response` includes the `HTTP.Request` that was sent in order to receive that given response.  
- `DecodingFailureRepresentable` has been changed to provide a `DecodingFailure` which can support more types of errors than just `DecodingError` (for example, a response which should not have been empty but is).


## Added Functionality

Along with the core changes described above, there are a ton of new added functionality present in Hyperspace 4.0.

### Swift Package Manager and Carthage Support

A long time coming - but beginning with 4.0, all three of the major dependency managers are supported. Cocoapods, Carthage and SPM - see the README for more details.

### Basic `async` / `await` Support

For users on Xcode 13.2+ and iOS 13+, basic `async` / `await` support has been added in the form of a simple extension on `BackendService`:

```swift
@available(iOS 13, tvOS 13, watchOS 6, *)
extension BackendServiceProtocol {

    public func execute<T, U>(request: Request<T, U>) async throws -> T

    public func executeWithResult<T, U>(request: Request<T, U>) async -> Result<T, U>
}
```

This is just the beginning of `async` / `await` support in Hyperspace, there will be more to come (and a deeper integration with the `Foundation` `async` APIs) in future versions.

### Request Recovery Additions

In addition to the changes to `RecoveryStrategy` described above, it is also possible to set a `recoveryTransformer` on an individual request - `public var recoveryTransformer: ((TransportFailure) -> TransportSuccess?)`. This property will allow you to attempt to consider any ordinarily failing `Request` as a success. If this handler exists, it is run before any of the `BackendService.recoveryStrategies`. If the handler returns a non-nil `TransportSuccess`, that success will be returned to the caller. If a recovery can not be completed, returning `nil` here will preserve the existing recovery functionality of the `BackendService`.

### Empty Decoding Strategy

Up until now, it has been cumbersome to effectively deal with empty responses with Hyperspace. `EmptyResponse` is not `Decodable`, and so in order to safely deal with these requests a custom `successTransformer` had to provided for each request.

In Hyperspace 4.0 though, this is more easily accomplished using `Request.withEmptyResponse` static function. This function takes similar input to the `Request` initializer, but also requires a single `EmptyDecodingStrategy`. This type governs how the "response" of the request is handled - allowing you to have much more control over how the process is handled. The `EmptyDecodingStrategy` ships with two defaults (in addition to the ability to create custom strategies).

 - `default`: Considers any successful HTTP status as a `TransportSuccess`, returning an `EmptyResponse`.
 - `validatedEmpty`: Ensures the response is actually empty, before returning an `EmptyResponse` in the `TransportSuccess`.

### CodableContainer

While `DecodableContainer` has existed in Hyperspace for quite some time, 4.0 brings with it `EncodableContainer`. This protocol functions incredibly similar to its decoding counterpart and is fully supported by `HTTP.Body`, making it easier than ever to package data into a `URLRequest`. In addition for types that can function as a container for both decoding and encoding, the typealias `CodableContainer` exists.

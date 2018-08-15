# Hyperspace 1.x-2.0 Migration Guide

This guide has been provided in order to ease the transition of existing applications using Hyperspace 1.x to the latest APIs, as well as to explain the structure of the new and changed functionality.

## Requirements

- iOS 8.0, tvOS 9.0, watchOS 2.0
- Xcode 9.4
- Swift 4.1

## Overview

Hyperspace 2.0 brings a ton of refinements and improvements to the simple core functionality of Hyperspace. There are a number of new APIs in Hyperspace 2, but fortunately, most is source-compatible with Hyperspace 1.x.

### Breaking Changes

#### `NetworkRequest` and Related Types Renamed

The first API change you'll encounter is one of the few source-breaking changes. The `NetworkRequest` protocol has been deprecated and renamed to `Request`. Similarly, `AnyNetworkRequest<T>` has been deprecated and renamed to `AnyRequest<T>`. In addition the `NetworkRequestDefaults` struct has been renamed to `RequestDefaults`. The use of Xcode 9's refactor tool should make light work of this migration.

#### `ErrorType` `associatedtype` Added to the `Request` Protocol

The second major change in Hyperspace 2 is the introduction of a new `associatedtype` on `Request` - `ErrorType`. In this new version, all errors returned to you are generically typed, we no longer lock you into using `AnyError`. Any custom request types you have created now have the option of replacing their usage of `AnyError` with a custom type conforming to `NetworkServiceFailureInitializable`. The usage of `AnyRequest<T>` should remain unaffected. Because we can now utilize this `NetworkServiceFailureInitializable` protocol to allow for the conversion of a `NetworkServiceFailure` into a generic error type of the consumer's choosing, we have also deprecated `BackendServiceError` and the associated `BackendServiceErrorInitializable` protocol. More information on the robust error handling capabilities of Hypersace 2.0 is available in [`Documentation/Guides/ErrorHandling.md`](../Guides/ErrorHandling.md).

#### URL Query Parameters No Longer Part of the `Request` Protocol

In order to simplify the `Request` protocol, we've changed the way URL query parameters are handled. If your request needs to use query parameters, it's now up to use the `generateRawQueryParametersString(from:)` in the extension on `URLQueryItem` to generate a query parameter string that you can append to the end of the request's URL. We've provided an `appendingQueryString(_:)` method on `URL` to help you generate a new `URL` from the generated query string. You can also just use the `appendingQueryItems(_:using:)` method on `URL` to shortcut this two-step process. 

#### `Request` Protocol `headers` Property Is Now a Stored Property

The `headers` property has changed from a `{ get }` read-only computed property to a `{ get set }` stored property. This change allowed for some helper functions regarding request headers to be added to `Request`: 
* `addingHeaders(_:)` - Adds/merges the provided headers with the receiver's headers.
* `usingHeaders(_:)` - Replaces the receiver's headers with the provided headers.

### Other Improvements

#### `HTTP.Status` Converted to `RawRepresentable` Struct

You can now specify custom HTTP status codes if you wish.

#### Container Decoding Improvements

We've improved the way you can handle decoding containers. More information is available in [`Documentation/Guides/Custom Decoding.md`](../Guides/Custom%20Decoding.md).

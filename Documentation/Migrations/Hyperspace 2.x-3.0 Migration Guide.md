# Hyperspace 2.x-3.0 Migration Guide

This guide has been provided in order to ease the transition of existing applications using Hyperspace 2.x to the latest APIs, as well as to explain the structure of the new and changed functionality.

## Requirements

- iOS 8.0, tvOS 9.0, watchOS 2.0
- Xcode 9.4
- Swift 4.1

## Overview

Hyperspace 3.0 brings more refinements to the core functionality of Hyperspace. There are a number of new APIs in Hyperspace 3, but fortunately, most is source-compatible with Hyperspace 2.x.

## Breaking Changes

### `Request` protocol requirement changes

The first breaking API change you'll encounter is a simplification to the `Data` transformation pipeline. In Hyperspace 2.x, the `Request` protocol requirement for transforming responses was as follows:

```swift
func transformData(_ data: Data, serviceSuccess: NetworkServiceSuccess) -> Result<ResponseType, ErrorType>
```

Because the `NetworkServiceSuccess` object contains a property for the `Data` object also being passed into the function, in Hyperspace 3.0 this requirement has been simplified to:

```swift
func transformSuccess(_ serviceSuccess: NetworkServiceSuccess) -> Result<ResponseType, ErrorType>
```

All the same information and objects are available, simply without the redundant `Data` parameter. This change has also been made throughout the default transformation blocks provided as part of `Hyperspace`, so this change may need to be made in multiple places to satisfy the new requirements.

### `DecodingFailureInitializable` initializer changes

A change has been made to provide failing type information to the initializer for objects conforming to `DecodingFailureInitializable` so that different decisions can be taken based on the type that failed to decode. The new requirement is as follows:

```swift
public init(error: DecodingError, decoding: Decodable.Type, data: Data)
```

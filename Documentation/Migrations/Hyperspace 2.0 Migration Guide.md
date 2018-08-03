# Hyperspace 2 Migration Guide

This guide has been provided in order to ease the transition of existing applications using Hyperspace 1.x to the latest APIs, as well as to explain the structure of the new and changed functionality.

## Requirements

- iOS 8.0, tvOS 9.0, watchOS 2.0
- Xcode 9.4
- Swift 4.0

## Overview

Hyperspace 2.0 brings a ton of refinements and improvements to the simple core functionality of Hyperspace. There are a number of new APIs in Hyperspace 2, but fortunately, most is source-compatible with Hyperspace 1.x

The first API change you'll encounter is one of the few source-breaking changes. The `NetworkRequest` protocol has been deprecated and renamed to `Request` and the similarly named `AnyNetworkRequest<T>` has been deprecated and renamed to `AnyRequest<T>`. The use of Xcode 9's refactor tool should make light work of this migration.

The second major change in Hyperspace 2 is the introduction of a new associated type on `Request` - `ErrorType`. In this new version, all errors returned to you are generically typed, we no longer lock you in to using `AnyError`. Any custom objects you have created now have the option of replacing their usage of `AnyError` with a custom type conforming to `NetworkServiceFailureInitializable`. Because we can now utilize this protocol to allow for the conversion of a `NetworkServiceFailure` into a generic error type, we have removed `BackendServiceError` and the associated `BackendServiceErrorInitializable` protocol. More information on the robust error handling capabilities of Hypersace 2.0 is available in the ErrorHandling guide.



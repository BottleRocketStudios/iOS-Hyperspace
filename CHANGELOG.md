## Master

#### Enhancements

## High Level Changes

* Add deprecated typealias to ease migration to 4.0
[Will McGinty](https://github.com/wmcginty)
[#124(https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/124)

* Changed underlying error in AnyError's NetworkServiceFailureInitializable implementation from NetworkServiceError to NetworkServiceFailure so it can return its failure response rather than nil.
[Richard Burgess](https://github.com/rickbdotcom)
[#95](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/95)

* Finished migrating all targets to Swift 5.
[Tyler Milner](https://github.com/tylermilner)
[#100](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/100)

* Added Carthage support.
[Ryan Gant](https://github.com/ganttastic)
[#101](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/101)

* Added Swift Package Manager support.
[Ryan Gant](https://github.com/ganttastic)
[#102](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/102)

* Migrate the request recovery strategy to the BackendServiceProtocol definition.
[Will McGinty](https://github.com/wmcginty)
[#110](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/110)

* Rename `RequestRecoveryStrategy` to `RecoveryStrategy` and allow multiple to be attached to a single `BackendService`. They are executed in the order they are initialized.
[Will McGinty](https://github.com/wmcginty)
[#117](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/117)

* Rename `DecodingFailureInitializable` to `DecodingFailureRepresentable` and make the failing `HTTP.Response` available during initialization.
[Will McGinty](https://github.com/wmcginty)
[#117](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/117)

* Create an `HTTP.Body` type to abstract the `Data` of a `URLRequest`.
[Will McGinty](https://github.com/wmcginty)
[#117](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/117)

* Several changes to simplify and refine `DecodableContainer`, as well as introduce `EncodableContainer` and `CodableContainer`.
[Will McGinty](https://github.com/wmcginty)
[#117](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/117)

* Convert `Request` protocol into a `struct` and eliminate the `AnyRequest` type.  A `URLRequestCreationStrategy` has been created to allow for differences in `URLRequest` generation.
[Will McGinty](https://github.com/wmcginty)
[#117](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/117)

* Rename `Network*` to `Transport*` to provide a clearer distinction between the role of the `BackendService` and `TransportService`. 
[Will McGinty](https://github.com/wmcginty)
[#117](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/117)

* Utilize `URLError` as part of the `Transporting` protocol to allow for more granularity and detail in error reporting.
[Will McGinty](https://github.com/wmcginty)
[#117](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/117)

* Make `TransportError` inits `public`..
  [Earl Gaspard](https://github.com/earlgaspard)
  [#121](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/121)

##### Bug Fixes

* Add an assertion to `BackendService` if a GET HTTP request with body data is detected.
[Will McGinty](https://github.com/wmcginty)
[#106](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/106)

## 3.2.1 (2019-07-19)

#### Enhancements

* None

##### Bug Fixes

* Make default implementations on `Recoverable` `public`.
[Will McGinty](https://github.com/wmcginty)
[#97](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/97)


## 3.2.0 (2019-07-11)

#### Enhancements

* Add URL modification capabilitites.
[Will McGinty](https://github.com/wmcginty)
[#92](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/92)


##### Bug Fixes

* None


## 3.1.0 (2019-05-07)

#### Enhancements

* Remove the type definitions deprecated in 3.0.0.
[Will McGinty](https://github.com/wmcginty)
[#77](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/77)

* Rename `dataTransformer` family of functions to  `successTransformer` to more accurately reflect their purpose.
[Will McGinty](https://github.com/wmcginty)
[#78](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/78)

* Cleaned up some TODOs in the code.
[Tyler Milner](https://github.com/tylermilner)
[#80](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/80)

* Add support for SSL certificate pinning
[Will McGinty](https://github.com/wmcginty)
[#84](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/84)

* Add support for futures and chaining requests.
[Pranjal Satija](https://github.com/pranjalsatija)
[#81](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/81)

* Fix 3.0.0 changelog.
[Pranjal Satija](https://github.com/pranjalsatija)
[#82](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/82)

* Added support for Swift 5
[Will McGinty](https://github.com/wmcginty)
[#88](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/88)

* Remove the `queryParameter` property deprecated in 2.0.0.
[Will McGinty](https://github.com/wmcginty)
[#90](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/90)

##### Bug Fixes

* None.


## 3.0.0 (2019-01-03)

##### Enhancements

* Fixed CHANGELOG for version 2.0.0/2.1.0.
  [Tyler Milner](https://github.com/tylermilner)
  [#73](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/73)

* Remove the type definitions deprecated in 2.0.0
  [Will McGinty](https://github.com/wmcginty)
  [#72](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/72)

* **[BREAKING]** Added failing type information to `DecodingFailureInitializable` allowing the API to make decisions based off of the type that failed to decode and deprecate dynamically keyed decoding.
  [Will McGinty](https://github.com/wmcginty)
  [#71](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/71)

* **[BREAKING]** Renamed `Request` protocol's `transformData(_:serviceSuccess:)` method to `transformSuccess(_:)`. The redundant `data` parameter was removed since the `NetworkServiceSuccess` makes it available as a property. Also simplified method signatures by introducing `RequestTransformBlock` typealias.
  [Tyler Milner](https://github.com/tylermilner)
  [#69](https://github.com/BottleRocketStudios/iOS-Hyperspace/issues/69)
  [#70](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/70)

* Fixed minor typo in CHANGELOG where the PR URL text didn't match the underlying PR number.
  [Tyler Milner](https://github.com/tylermilner)
  [#68](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/68)

##### Bug Fixes

* None.


## 2.1.0 (2018-09-20)

##### Enhancements

* Mark `Request.queryParameters` as deprecated in v2.
  [Daniel Larsen](https://github.com/GrandLarseny)
  [#59](https://github.com/BottleRocketStudios/iOS-Hyperspace/issues/59)
  [#61](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/61)

* Added notes about `headers` property changes to migration guide.
  [Tyler Milner](https://github.com/tylermilner)
  [#60](https://github.com/BottleRocketStudios/iOS-Hyperspace/issues/60)
  [#62](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/62)

* Updated Travis-CI to Xcode 9.4.
  [Tyler Milner](https://github.com/tylermilner)
  [#63](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/63)

* Add `headers` property to `HTTP.Response`. The method signature of `Request`’s `transformData(_:)` method has changed. If you implement a custom `transformData(_:)` method, you will need to replace it with `transformData(_:serviceSuccess:)`.
  [Earl Gaspard](https://github.com/earlgaspard)
  [#64](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/64)

* Updated Result dependency to version 4.0, updated Travis-CI to Xcode 10, and updated Swift version from Swift 4.1 to Swift 4.2 (for both library and sample app).
  [Tyler Milner](https://github.com/tylermilner)
  [#67](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/67)

##### Bug Fixes

* None.


## 2.0.0 (2018-08-03)

##### Enhancements

* Two new error-facing protocols were added. `NetworkServiceFailureInitializable` represents a `Swift.Error` that can be initialized from a `NetworkServiceFailure` object. `DecodingFailureInitializable` represents a `Swift.Error` that can be initialized from a `DecodingError` as a result of decoding `Data`. These conformances have been added as extensions to `AnyError` (meaning `AnyRequest` usage is unaffected). As a result of these new protocols, the `BackendServiceError` type has been removed. Types conforming to `Request` now have an associated `ErrorType` which must conform to `NetworkServiceFailureInitializable`. If a request generates any sort of failure response, the custom error type will be initialized from it instead of returning a generic `BackendServiceError`. In addition, if `Request.ErrorType` conforms to `DecodingFailureInitializable`, the custom error type will be instantiated and returned.
    [Will McGinty](https://github.com/wmcginty)
    [#38](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/38)

* Added a new initalizer to `AnyRequest` which accepts a `String` value designating the key of JSON at which to begin decoding.
    [Will McGinty](https://github.com/wmcginty)
    [#41](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/41)

* Separated the generation/encoding of the URL query from the `Request` object into an extension `URL`.
    [Will McGinty](https://github.com/wmcginty)
    [#40](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/40)

* Add functionality to `NetworkReqest` to allow for replacing and adding to the HTTP headers.
    [Will McGinty](https://github.com/wmcginty)
    [#43](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/43)

* Simplify usage of `DecodableContainer` types with `JSONDecoder`
    [Will McGinty](https://github.com/wmcginty)
    [#44](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/44)

* Add a subsystem which can perform transparent error handling using `RequestRecoveryStrategy`.
    [Will McGinty](https://github.com/wmcginty)
    [#45](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/45)

* Simplify usage of `dataTransfomer` extensions with custom error types
    [Will McGinty](https://github.com/wmcginty)
    [#47](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/47)

* Add `HTTP.HeaderValue` for JSON API specification.
    [Earl Gaspard](https://github.com/earlgaspard)
    [#46](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/46)

* Converted `HTTP.Status`nested types (`HTTP.Status.Success`, `HTTP.Status.ClientError`, etc.) from enums to `RawRepresentable` structs. This keeps the library more open for extension by allowing clients to more easily specify and use custom HTTP status codes.
    [Tyler Milner](https://github.com/tylermilner)
    [#49](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/49)
    [#50](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/50)

* Implemented synthesized `Equatable` and `Hashable` conformance that was introduced in Swift 4.1.
    [Tyler Milner](https://github.com/tylermilner)
    [#51](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/51)

* Renamed `NetworkRequest` and `AnyNetworkRequest` to `Request` and `AnyRequest`.
    [Will McGinty](https://github.com/wmcginty)
    [#52](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/52)

##### Bug Fixes

* None.


## 1.1.1 (2018-05-10)

##### Enhancements

* Removed some duplicate code for `invalidHTTPResponseError(_:)` in `NetworkServiceHelper`.
  [Tyler Milner](https://github.com/tylermilner)
  [#19](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/19)

* Formatting and content updates for the readme.
  [Tyler Milner](https://github.com/tylermilner)
  [#20](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/20)

* General unit test organization and cleanup.
  [Tyler Milner](https://github.com/tylermilner)
  [#22](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/22)

* Updated CLA URL.
  [Will McGinty](https://github.com/wmcginty)
  [#23](https://github.com/BottleRocketStudios/iOS-Hyperspace/issues/23)
  [#24](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/24)

* Added `CHANGELOG.md`. From now on, all new bugfix/feature PR's will require an entry in the changelog.
  [Tyler Milner](https://github.com/tylermilner)
  [#27](https://github.com/BottleRocketStudios/iOS-Hyperspace/issues/27)
  [#29](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/29)

* Added BackendServiceHelper for public interfacing.
  [Earl Gaspard](https://github.com/earlgaspard)
  [#31](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/31)

* Upgraded project to Xcode 9.3/Swift 4.1.
  [Tyler Milner](https://github.com/tylermilner)
  [#25](https://github.com/BottleRocketStudios/iOS-Hyperspace/issues/25)
  [#30](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/30)

##### Bug Fixes

* None.


## 1.1.0 (2018-02-08)

##### Enhancements

* Adjusted project structure to better support Travis-CI. CI is fully up-and-running on all 3 currently supported platforms. **Carthage** is now required to work on the library and run the example projects (**Cocoapods** is no longer used). Clone the repo, run `carthage update`, and then open `Hyperspace.xcworkspace` to get started.
  [Tyler Milner](https://github.com/tylermilner)
  [#3](https://github.com/BottleRocketStudios/iOS-Hyperspace/issues/3)

* Can now `cancelAllTasks()` on `BackendServiceProtocol`.
  [Will McGinty](https://github.com/wmcginty)
  [#4](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/4)

* `NetworkService` logic extracted into `NetworkServiceHelper` to better support future framework compatibility with `URLSessionDelegate` implementations.
  [Will McGinty](https://github.com/wmcginty)
  [#5](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/5)

* `NetworkService` can now represent loading via the global network activity indicator shown in the device's status bar. Just initialize your `NetworkService` with a `NetworkActivityIndicatable` (ex: `NetworkService(networkActivityIndicatable: UIApplication.shared)`).
  [Will McGinty](https://github.com/wmcginty)
  [#2](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/2)

* Improved code coverage > 90%.
  [Adamcbrz](https://github.com/Adamcbrz)
  [#1](https://github.com/BottleRocketStudios/iOS-Hyperspace/issues/1)
  [#10](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/10)

* Re-enabled SwiftLint.
  [Will McGinty](https://github.com/wmcginty)
  [#9](https://github.com/BottleRocketStudios/iOS-Hyperspace/issues/9)
  [#11](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/11)

* Added code coverage badge.
  [Amanda Chappell](https://github.com/achappell)
  [#7](https://github.com/BottleRocketStudios/iOS-Hyperspace/issues/7)
  [#12](https://github.com/BottleRocketStudios/iOS-Hyperspace/pull/12)

##### Bug Fixes

* None.


## 1.0.0 (2017-12-18)

##### Initial Release

This is our initial release of Hyperspace. Enjoy!

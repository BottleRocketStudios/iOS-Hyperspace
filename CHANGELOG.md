## Master

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

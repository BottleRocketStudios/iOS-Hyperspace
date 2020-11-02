# Hyperspace

[![CI Status](https://img.shields.io/travis/BottleRocketStudios/iOS-Hyperspace/master.svg)](https://travis-ci.org/BottleRocketStudios/iOS-Hyperspace)
[![Version](https://img.shields.io/cocoapods/v/Hyperspace.svg?style=flat)](http://cocoapods.org/pods/Hyperspace)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/Hyperspace.svg?style=flat)](http://cocoapods.org/pods/Hyperspace)
[![Platform](https://img.shields.io/cocoapods/p/Hyperspace.svg?style=flat)](http://cocoapods.org/pods/Hyperspace)
[![codecov](https://codecov.io/gh/BottleRocketStudios/iOS-Hyperspace/branch/master/graph/badge.svg)](https://codecov.io/gh/BottleRocketStudios/iOS-Hyperspace)
[![codebeat badge](https://codebeat.co/badges/ebf9c2d1-d736-4d75-85cc-5c0feb19cab1)](https://codebeat.co/projects/github-com-bottlerocketstudios-ios-hyperspace-master-5e50b1a2-1d6c-48a3-8d1f-2407b2f439ba)


## Purpose

This library provides a simple abstraction around URLSession and HTTP. There are a few main goals:

* Keep things simple.
* Keep the overall library size to a minimum. Of course, there will be some boilerplate involved (such as the `HTTP` definitions), but our main goal is to keep the library highly functional and maintainable without over-engineering.
* Tailor the library to the networking use cases that we encounter the most often. We will continue to add features based on the common needs across all of the apps that we build.

## Key Concepts

* **HTTP** - Contains standard HTTP definitions and types. If you feel something is missing from here, please submit a pull request!
* **Request** - A struct that defines the details of a network request, including the desired result and error types. This is basically a thin wrapper around `URLRequest`, utilizing the definitions in `HTTP`.
* **TransportService** - Uses a `TransportSession` (`URLSession` by default) to execute `URLRequests`. Deals with raw `HTTP` and `Data`.
* **BackendService** - Uses a `TransportService` to execute `Requests`. Transforms the raw `Data` returned from the `TransportService` into the response model type defined by the `Request`. **This is the main worker object your app will deal with directly**.

## Usage

### 1. Create Requests

You have multiple options when creating requests- including creating static functions to reduce the boilerplace when creating a `Request` object, or you can simply create them locally. In addition, you can still create your own custom struct that wraps and vends a `Request` object if your network requests are complex.

#### Option 1 - Extending `Request` 

The example below illustrates how to create an extension on `Request` which can drastically reduce the boilerplate when creating a request to create a new post in something like a social network feed. It takes advantage of the many defaults into `Request` (all are which are customizable) to keep the definition brief:
```swift
extension Request {
    static func createPost(_ post: NewPost) -> Request<Post, AnyError> {
        return Request(method: .post, url: URL(string: "https://jsonplaceholder.typicode.com/posts")!, headers: [.contentType: .applicationJSON],
                       body: try? HTTP.Body(post))
    }
}
```

#### Option 2 - Define Each `Request` Locally

```swift
let createPostRequest = Request(method: .post, url: URL(string: "https://jsonplaceholder.typicode.com/posts")!, headers: [.contentType: .applicationJSON],
        body: try? HTTP.Body(post))
```

#### Option 3 - Create a `CreatePostRequest` that wraps a `Request`
```swift
struct CreatePostRequest {
    let newPost: NewPost
    
    var request: Request<Post, AnyError> {
        return Request(method: .post, url: URL(string: "https://jsonplaceholder.typicode.com/posts")!, headers: [.contentType: .applicationJSON],
                       body: try? HTTP.Body(post))
    }
}
```

For the above examples, the `Post` response type and `NewPost` body are defined as follows:
```swift
struct Post: Decodable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}
```

```swift
struct NewPost: Encodable {
    let userId: Int
    let title: String
    let body: String
}
```

### 2. Create Request defaults (optional)

To avoid having to define default `Request` property values for every request in your app, it can be useful to rely on the `RequestDefaults` provided by Hyperspace. These can even be customized:
```swift
RequestDefaults.defaultCachePolicy = .reloadIgnoringLocalCacheData // Default cache policy is '.useProtocolCachePolicy'
RequestDefaults.defaultDecoder = MyCustomDecoder() // Default decoder is JSONDecoder
RequestDefaults.defaultTimeout = 60 // Default timeout is 30 seconds
```

### 3. Create a BackendService to execute your requests

We recommend adhering to the [Interface Segregation](https://en.wikipedia.org/wiki/Interface_segregation_principle) principle by creating separate "controller" objects for each section of the API you're communicating with. Each controller should expose a set of related funtions and use a `BackendService` to execute requests. However, for this simple example, we'll just use `BackendService` directly as a `private` property on the view controller:
```swift
class ViewController: UIViewController {

    private let backendService = BackendService()

    // Rest of your view controller code...
}
```

### 4. Instantiate your Request

Let's say our view controller is supposed to create the post whenever the user taps the "send" button. Here's what that might look like:
```swift
@IBAction private func sendButtonTapped(_ sender: UIButton) {
    let title = ... // Get the title from a text view in the UI...
    let message = ... // Get the message from a text view/field in the UI...
    let post = NewPost(userId: 1, title: title, body: message)

    let createPostRequest = CreatePostRequest(newPost: post)

    // Execute the network request...
}
```

### 5. Execute the Request using the BackendService

For the above example, here's how you would execute the request and parse the response. While all data transformation happens on the background queue that the underlying URLSession is using, all `BackendService` completion callbacks happen on the main queue so there's no need to worry about threading before you update UI. Notice that the type of the success response's associated value below is a `Post` struct as defined in the `CreatePostRequest` above:
```swift
backendService.execute(request: createPostRequest) { [weak self] result in
    debugPrint("Create post result: \(result)")

    switch result {
    case .success(let post):
        // Insert the new post into the UI...
    case .failure(let error):
        // Alert the user to the error...
    }
}
```

## Example

To run the example project, you'll first need to use [Carthage](https://github.com/Carthage/Carthage) to install Hyperspace's dependency ([BrightFutures](https://github.com/Thomvis/BrightFutures).

After [installing Carthage](https://github.com/Carthage/Carthage#installing-carthage), clone the repo:

```bash
git clone https://github.com/BottleRocketStudios/iOS-Hyperspace.git
```

Next, use Carthage to install the dependencies:

```bash
carthage update
```

From here, you can open up `Hyperspace.xcworkspace` and run the examples:

### Shared Code

* `Models.swift`, `Requests.swift`
    * Sample models and network requests shared by the various examples.

### Example Targets

* **Hyperspace-iOSExample**
    * `ViewController.swift`
        * View a simplified example of how you might use this in your iOS app.
* **Hyperspace-tvOSExample**
    * `ViewController.swift`
        * View a simplified example of how you might use this in your tvOS app (this is essentially the same as the iOS example).
* **Hyperspace-watchOSExample Extension**
    * `InterfaceController.swift`
        * View a simplified example of how you might use this in your watchOS app.

### Playgrounds

* **Playground/Hyperspace.playground**
    * View and run a single file that defines models, network requests, and executes the requests similar to the example targets above.
* **Playground/Hyperspace_AnyRequest.playground**
    * The same example as above, but using the `AnyRequest<T>` struct.
* **Playground/Hyperspace_DELETE.playground**
    * An example of how to deal with requests that don't return a result. This is usually common for DELETE requests.

## Requirements

* iOS 8.0+
* tvOS 9.0+
* watchOS 2.0+
* Swift 5.0

## Installation

### Cocoapods

Hyperspace is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Hyperspace'
```

### Carthage

Add the following to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

```
github "BottleRocketStudios/iOS-Hyperspace"
```

Run `carthage update` and follow the steps as described in Carthage's [README](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).

NOTE: Don't forget to add both `Hyperspace.framework` and the `BrightFutures.framework` dependency to your project (if using the `Futures` subspec).

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/BottleRocketStudios/iOS-Hyperspace.git", from: "3.2.1")
]
```

## Author

[Bottle Rocket Studios](https://www.bottlerocketstudios.com/)

## License

Hyperspace is available under the Apache 2.0 license. See the LICENSE.txt file for more info.

# Hyperspace

[![CI Status](http://img.shields.io/travis/BottleRocketStudios/iOS-Hyperspace.svg?style=flat)](https://travis-ci.org/BottleRocketStudios/iOS-Hyperspace)
[![Version](https://img.shields.io/cocoapods/v/Hyperspace.svg?style=flat)](http://cocoapods.org/pods/Hyperspace)
[![License](https://img.shields.io/cocoapods/l/Hyperspace.svg?style=flat)](http://cocoapods.org/pods/Hyperspace)
[![Platform](https://img.shields.io/cocoapods/p/Hyperspace.svg?style=flat)](http://cocoapods.org/pods/Hyperspace)

## Purpose

This library provides a simple abstraction around URLSession and HTTP. There are a few main goals:

* Wrap up all the HTTP boilerplate (method, headers, status codes, etc.) to allow your app to deal with them in a type-safe way.
* Provide a thin wrapper around URLSession:
    * Make error handling more pleasant.
    * Make it easy to define the details of your request and the model type you want to get back.
* Keep things simple.
    * There are currently around 600 SLOC, with about a third of that being boilerplate HTTP definitions.
    * Of course, complexity will increase over time as new features are added, but we're not trying to cover every possible networking use case here.

## Key Concepts

* HTTP - Contains standard HTTP definitions and types. If you feel something is missing from here, please submit a pull request!
* NetworkRequest - A protocol that defines the details of a request, including the desired result type. This is basically a thin wrapper around `URLRequest`, utilizing the definitions in *HTTP*.
* NetworkService - Uses a *NetworkSession* (`URLSession` by default) to execute `URLRequests`. Deals with raw *HTTP* and `Data`.
* BackendService - Uses a *NetworkService* to execute *NetworkRequests*. Transforms the raw `Data` returned from the *NetworkService* into the response model type defined by the *NetworkRequest*. **This is the main worker object your app will deal with directly**.

## Usage

### 1. Create NetworkRequests

You have two options to create requests - create your own struct or class that conforms to the `NetworkRequest` protocol or by utilize the built-in `AnyNetworkRequest<T>` type-erased struct. Creating your own structs or classes is a bit more explicit, but can help encourage encapsulation and testability if your requests are complex. The `AnyNetworkRequest<T>` struct is generally fine to use for most cases.

#### Option 1 - Adopting the `NetworkRequest` protocol

The `CreatePostRequest` in the example below represents a simple request to create a new post in something like a social network feed:
```swift
struct CreatePostRequest: NetworkRequest {
    // Define the model we want to get back
    typealias ResponseType = Post
    typealias ErrorType = AnyError

    // Define NetworkRequest property values
    var method: HTTP.Method = .post
    var url = URL(string: "http://jsonplaceholder.typicode.com/posts")!
    var queryParameters: [URLQueryItem]?
    var headers: [HTTP.HeaderKey: HTTP.HeaderValue]? = [.contentType: .applicationJSON]
    var body: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(newPost)
    }

    // Define any custom properties needed
    private let newPost: NewPost

    // Initializer
    init(newPost: NewPost) {
        self.newPost = newPost
    }
}
```

#### Option 2 - Using the `AnyNetworkRequest<T>` struct

```swift
let createPostRequest = AnyNetworkRequest<Post>(method: .post,
                                                url: URL(string: "http://jsonplaceholder.typicode.com/posts")!,
                                                headers: [.contentType: .applicationJSON],
                                                body: postBody)
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

### 2. Create NetworkRequest defaults (optional)

To avoid having to define default `NetworkRequest` property values for every request in your app, it can be useful to extend `NetworkRequest` with the defaults you want every request to have:
```swift
extension NetworkRequest {
    var cachePolicy: URLRequest.CachePolicy {
        return .reloadIgnoringLocalCacheData
    }

    var timeout: TimeInterval {
        return 60.0
    }
}
```

Alternatively, you can also modify the values of `NetworkRequestDefaults` directly:
```swift
NetworkRequestDefaults.defaultTimeout = 60 // Default timeout is 30 seconds
NetworkRequestDefaults.defaultCachePolicy = .reloadIgnoringLocalCacheData // Default cache policy is '.useProtocolCachePolicy'
```

### 3. Create a BackendService to execute your requests

We recommend adhering to the [Interface Segregation](https://en.wikipedia.org/wiki/Interface_segregation_principle) principle by creating separate "controller" objects for each section of the API you're communicating with. Each controller should expose a set of related funtions and use a `BackendService` to execute requests. However, for this simple example, we'll just use `BackendService` directly as a `private` property on the view controller:
```swift
class ViewController: UIViewController {

    private let backendService = BackendService()
    
    // Rest of your view controller code...
}
```

### 4. Instantiate your NetworkRequest

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

### 5. Execute the NetworkRequest using the BackendService

For the above example, here's how you would execute the request and parse the response. While all data transformation happens on the background queue that the underlying URLSession is using, all `BackendService` completion callbacks happen on the main queue so there's no need to worry about threading before you update UI. Notice that the type of the success response's associated value below is a `Post` struct as defined in the `CreatePostRequest` above:
```swift
backendService.execute(request: createPostRequest) { [weak self] (result) in
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

To run the example project, clone the repo, `cd Example`, and then run `pod install`. From here, you can run the examples:

* Playground/Hyperspace.playground
    * View and run a single file that defines models, network requests, and executes the requests similar to the example above.
* Playground/Hyperspace.Hyperspace_AnyNetworkRequest.playground
    * The same example as above, but using the `AnyNetworkRequest<T>` struct.
* Playground/Hyperspace_DELETE.playground
    * An example of how to deal with requests that don't return a result. This is usually common for DELETE requests.
* ViewController.swift, Models.swift, and NetworkRequests.swift
    * View a simplified example of how you might use this in your app.

## Requirements

* iOS 8.0+
* Swift 4

## Installation

Hyperspace is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Hyperspace"
```

## Author

[Bottle Rocket Studios](https://www.bottlerocketstudios.com/)

## License

Hyperspace is available under the Apache 2.0 license. See the LICENSE.txt file for more info.

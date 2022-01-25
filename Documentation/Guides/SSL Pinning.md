### SSL Pinning

SSL Pinning is the practice of limiting the set of server certificates your app trusts when making network requests, in addition to the trust verification the operating system performs. This, in combination with HTTPS, allows you to better preserve the privacy and integrity of the information you are transmitting back and worth to a backend server.

Hyperspace has a built-in mechanism for implementing SSL pinning which is available by default when using Swift Package Manager or Carthage, and using the `Pinning` subspec when using Cocoapods. But, depending on your deployment target, the recommended approach to certificate pinning will differ.


#### iOS 14+

If you are deploying on iOS 14 or above, it is recommended to use the new `NSPinnedDomains` Info.plist key. This means that you do not need to use the `TrustConfiguration` in Hyperspace, and can instead rely almost entirely on the operating system to perform the extra trust validations on server SSL certificates.

More information on how to implement this new `NSPinnedDomains` Info.plist key, as well as information around other considerations and strategies involving pinning is available [here](https://developer.apple.com/forums/thread/672291), with the standard developer documentation [here](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity/nspinneddomains).


#### Older iOS Versions

On the other hand, if you have not yet dropped iOS 13 - you can use the Hyperspace implementation. The basics involve creating a `TrustConfiguration` that details the certificates that your app should trust, and then utilizing a `TrustValidator` to check each incoming server SSL certificate against the previously defined configuration. To make things simpler, Hyperspace includes a `TrustValidatingTransportService` that can be used with any `BackendService` that automates this process.

For example, let's assume we want to pin all our connections to https://jsonplaceholder.typicode.com. Effectively this means that at the time the app connects to that TLS network, the server will provide it's SSL certificate. If the certificate the app receives does not match one that we are looking for (even if the certificate is valid) the request will be rejected.

The first thing we need to do then, is create a certificate to pin to. Assuming you have `certificate.cer` for this domain, you can pass this certificate directly to the `TrustConfiguration` using the `DomainConfiguration(domain:certificates:)`. This initializer will automatically create a formatted hash for this certificate and use that as the basis for pinning.

If you would like, instead of embedding certificates directly into the bundle, you can manually create this hash. A SHA-256 hash of the public key of the certificate is used by the `TrustValidator` under the hood. Again, using the `jsonplaceholder.typicode.com` example - you can use a variety of tools to view the details of the certificate itself (include Safari - click the padlock in the address bar). This will allow you to see the hex bytes of the public key of the certificate. At the time of writing, these are:

`04 B9 ED ED FC C4 3D 5D 2B C6 64 C1 53 A3 B6 52 56 7B BF E2 86 AB FF 94 97 FD 9C CA 11 3B 23 2D 8B 74 7B 94 7F 99 00 13 FA D1 01 73 00 B3 90 3B 74 F2 20 D7 47 53 D4 F8 33 58 A5 07 F5 12 39 8A 7E`

These bytes can then be run through a SHA-256 hash (an easy way to do this using the `CertificateHasher` in Hyperspace) to produce your pinning hash: `XlCPXC6IrttTF9Y1887kS+efCCf3uFjHW6D1TUI9f+Q=`. This hash can then be passed into a `DomainConfiguration` using `.init(domain:pinningHashes:)` or `.init(domain:encodedPinningHashes:)` (the latter of which is Base64 encoded). Please note that the hash required for the pinning implementation in Hyperspace is not identical to the one that the `NSPinnedDomains` key uses in iOS 14+.

Once the `TrustConfiguration` has been created with 1+ `DomainConfigurations`, the final step is to tell Hyperspace how to validate this configuration at request-time. This can be done by manually utilizing a `TrustValidator` at the appropriate time, by calling `validator.handle(challenge:,handler:). In the vast majority of cases though, it is simpler to use the provided `TrustValidatingTransportService` which builds upon `TransportService` to automatically provide this functionality when the app receives an authentication challenge through the `URLSessionDelegate`.

Once this is in place you should be able to observe the effects of pinning, for example using a proxy tool like Charles. When the proxy is not running, the certificate should be the "real" one and any requests you make to the pinned domain should succeed. Turning on the proxy will instead use a different certificate, which will cause any requests to the pinned domain to return an error, similar to the one below:

``` 
failure(TransportFailure(error: Hyperspace.TransportError(code: Hyperspace.TransportError.Code.cancelled, underlyingError: Optional(Error Domain=NSURLErrorDomain Code=-999 \"cancelled\" UserInfo={NSErrorFailingURLStringKey=https://jsonplaceholder.typicode.com/users/1, NSErrorFailingURLKey=https://jsonplaceholder.typicode.com/users/1, _NSURLErrorRelatedURLSessionTaskErrorKey=(\n    \"LocalDataTask <AA005DD8-5591-4437-86E7-210A92624C73>.<1>\"\n), _NSURLErrorFailingURLSessionTaskErrorKey=LocalDataTask <AA005DD8-5591-4437-86E7-210A92624C73>.<1>, NSLocalizedDescription=cancelled})), request: Hyperspace.HTTP.Request(url: Optional(https://jsonplaceholder.typicode.com/users/1), method: Optional(\"GET\"), headers: Optional([:]), body: nil), response: nil))"







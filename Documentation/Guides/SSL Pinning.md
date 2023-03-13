# SSL Pinning

SSL Pinning is the practice of limiting the set of server certificates your app trusts when making network requests. This occurs in addition to the trust verification the operating system performs by default. This, in combination with HTTPS, better preserves the privacy and integrity of the information you are transmitting back-and-forth to a backend server.

If your deployment target is set to iOS 14 or above, it is recommended to use the new `NSPinnedDomains` Info.plist key. This means that you can rely almost entirely on the operating system to perform the extra trust validations on server SSL certificates.

More information on how to implement this new `NSPinnedDomains` Info.plist key, as well as information around other considerations and strategies involving pinning, is available [here](https://developer.apple.com/news/?id=g9ejcf8y), with the standard developer documentation on the `NSPinnedDomains` Info.plist key [here](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity/nspinneddomains).


## Pinning Considerations

In addition to the implementation, there are a number of other things to consider when it comes to SSL certificate pinning. When set up correctly, pinning adds an additional layer of security to your network communications. But when set up poorly, it can become an ongoing maintenance nightmare. Here are a few questions to ask as you consider how to implement pinning:

1) Do you _need_ pinning? iOS and TLS are already doing a lot of work for your users behind the scenes. Is the information you are transmitting worth the time and coordination of implementing pinning?

2) What happens to a given version of the app when the certificate expires? The server will change its certificate, which will cause pinning to fail. How will you handle this? By default, a pinning failure will cause the request to fail, meaning the user experience of your app will likely be broken. One quick app-side fix for this would be to utilize `DomainConfiguration.expirationPolicy.allow(after:)` functionality, which will automatically stop enforcing pinning to a given domain after a certain date (for example, the certificate's expiration date). Keep in mind that while continually shipping updates to your app containing new certificates is a viable strategy, it effectively gives each version of your app a shelf-life that can not be increased.

3) What happens if a certificate is changed unexpectedly? Again, this will likely cause the user experience of your app to break, and should be treated as a critical consideration in your implementation of pinning. Fortunately, both the `NSPinnedDomains` and `DomainConfiguration` APIs can pin against a list of certificates, meaning that this scenario can be avoided with planning.

4) Do you want pinning to be enabled on all environments? Only production environments? Only production builds? All of these options present testing concerns that should be addressed before the implementation is in place. Keep in mind that pinning will effectively not allow the use of proxy tools, making this question of huge importance.

Apple has published some of their [own thoughts](https://developer.apple.com/news/?id=g9ejcf8y) on when it is most appropriate to pin an SSL certificate, and how to plan for success in the long term when doing so.

/// Autogenerated!!! There's currently a problem with Xcode not include SPM resources when testing. So I've copied this file
/// from the SPM derived data for testing. You can find it at ~/Library/Developer/Xcode/DerivedData/**/Build/Intermediates.noindex/Hyperspace.build/Debug/HyperspaceTests.build/DerivedSources/resource_bundle_accessor.swift
///
/// See the following bug for a bit more details: https://github.com/apple/swift-package-manager/issues/4500

import class Foundation.Bundle
import class Foundation.ProcessInfo
import struct Foundation.URL

private class BundleFinder {}

extension Foundation.Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static var REPLACE_ME_module: Bundle = {
        let bundleName = "Hyperspace_HyperspaceTests"

        let overrides: [URL]
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["PACKAGE_RESOURCE_BUNDLE_URL"] {
            overrides = [URL(fileURLWithPath: override)]
        } else {
            overrides = []
        }
        #else
        overrides = []
        #endif

        let candidates = overrides + [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: BundleFinder.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL,
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        fatalError("unable to find bundle named Hyperspace_HyperspaceTests")
    }()
}

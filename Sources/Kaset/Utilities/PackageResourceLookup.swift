import SwiftUI

/// Anchors `Bundle(for:)` to the module that owns the resources.
private final class BundleToken {}

enum PackageResourceLookup {
    private static let resourceBundleName = "Kaset_Kaset.bundle"
    private static let accentColorName = "AccentColor"

    static let bundle = Self.candidateBundles.first
    static let localizationBundle = Self.bundle

    /// The brand accent as a platform colour, for views built with AppKit/UIKit (e.g. table cells).
    static let brandAccentNSColor: PlatformColor = {
        for bundle in [Bundle.main] + candidateBundles {
            #if os(macOS)
                if let color = NSColor(named: NSColor.Name(accentColorName), bundle: bundle) {
                    return color
                }
            #else
                if let color = UIColor(named: accentColorName, in: bundle, compatibleWith: nil) {
                    return color
                }
            #endif
        }

        return PlatformColor(red: 1.0, green: 0.0, blue: 0.337, alpha: 1.0)
    }()

    static let brandAccent = Color(platformColor: Self.brandAccentNSColor)

    private static let bundleSearchRoots: [Bundle] = {
        var bundles: [Bundle] = [Bundle.main]
        bundles.append(contentsOf: Bundle.allBundles)
        bundles.append(contentsOf: Bundle.allFrameworks)

        var uniqueBundles: [Bundle] = []
        var seenPaths = Set<String>()

        for bundle in bundles {
            guard seenPaths.insert(bundle.bundleURL.path).inserted else { continue }
            uniqueBundles.append(bundle)
        }

        return uniqueBundles
    }()

    private static let candidateBundles: [Bundle] = {
        var bundles: [Bundle] = []
        var seenPaths = Set<String>()

        // 1. Try to find the bundle via current module reference (most reliable)
        // In SwiftPM, targets with resources have a generated Bundle.module.
        // We use a known class from this target to find the right bundle.
        let classBundle = Bundle(for: BundleToken.self)
        if let moduleBundleURL = classBundle.resourceURL?.appendingPathComponent(Self.resourceBundleName),
           let moduleBundle = Bundle(url: moduleBundleURL)
        {
            bundles.append(moduleBundle)
            seenPaths.insert(moduleBundleURL.path)
        }

        // 2. Standard search roots
        var candidateURLs: [URL] = Self.bundleSearchRoots.flatMap { bundle in
            Self.candidateURLs(for: bundle)
        }
        candidateURLs.append(contentsOf: Self.bundleCandidatesInBuildDirectory())

        for url in candidateURLs {
            guard seenPaths.insert(url.path).inserted else { continue }
            guard let bundle = Bundle(url: url) else { continue }
            bundles.append(bundle)
        }

        return bundles
    }()

    private static func candidateURLs(for bundle: Bundle) -> [URL] {
        [
            bundle.resourceURL?.appendingPathComponent(self.resourceBundleName),
            bundle.bundleURL.appendingPathComponent(self.resourceBundleName),
            bundle.bundleURL.deletingLastPathComponent().appendingPathComponent(self.resourceBundleName),
            bundle.executableURL?.deletingLastPathComponent().appendingPathComponent(self.resourceBundleName),
        ]
        .compactMap(\.self)
    }

    private static func bundleCandidatesInBuildDirectory() -> [URL] {
        let fileManager = FileManager.default
        let buildDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
            .appendingPathComponent(".build", isDirectory: true)
        guard let enumerator = fileManager.enumerator(
            at: buildDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var bundleURLs: [URL] = []

        for case let url as URL in enumerator where url.lastPathComponent == Self.resourceBundleName {
            bundleURLs.append(url)
        }

        return bundleURLs
    }
}

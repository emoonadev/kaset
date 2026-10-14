import CoreGraphics
import SwiftUI

#if os(macOS)
    import AppKit

    typealias PlatformImage = NSImage
    typealias PlatformColor = NSColor
    typealias PlatformView = NSView
#else
    import UIKit

    typealias PlatformImage = UIImage
    typealias PlatformColor = UIColor
    typealias PlatformView = UIView
#endif

// MARK: - Cross-platform helpers

extension PlatformImage {
    /// Decodes an image from encoded data (PNG, JPEG, …).
    static func decoded(from data: Data) -> PlatformImage? {
        PlatformImage(data: data)
    }

    /// Wraps a `CGImage` at its pixel size.
    static func wrapping(_ cgImage: CGImage) -> PlatformImage {
        #if os(macOS)
            NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #else
            UIImage(cgImage: cgImage)
        #endif
    }

    /// The backing `CGImage`, if any.
    var platformCGImage: CGImage? {
        #if os(macOS)
            self.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
            self.cgImage
        #endif
    }
}

extension PlatformColor {
    /// The system accent colour (`controlAccentColor` on macOS, `tintColor` on iOS).
    static var platformAccent: PlatformColor {
        #if os(macOS)
            NSColor.controlAccentColor
        #else
            UIColor.tintColor
        #endif
    }
}

extension Color {
    /// Bridges a platform colour into SwiftUI.
    init(platformColor: PlatformColor) {
        #if os(macOS)
            self.init(nsColor: platformColor)
        #else
            self.init(uiColor: platformColor)
        #endif
    }
}

extension PlatformView {
    /// Autoresizing mask that tracks the superview's width and height.
    static var fillAutoresizing: AutoresizingMask {
        #if os(macOS)
            [.width, .height]
        #else
            [.flexibleWidth, .flexibleHeight]
        #endif
    }
}

/// Cross-platform accessibility flags.
enum PlatformAccessibility {
    @MainActor
    static var reduceMotion: Bool {
        #if os(macOS)
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #else
            UIAccessibility.isReduceMotionEnabled
        #endif
    }
}

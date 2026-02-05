//
//  GDWrapper.swift
//  Vaultown
//
//  Minimal libgd wrapper for image generation with Swift 6 compatibility
//
//  Created by Maxim Lanskoy on 29.01.2026.
//

import Foundation
import gd

// MARK: - Color

/// A color value for drawing operations
public struct GDColor: Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Convert to libgd color integer
    func toGDColor(in image: gdImagePtr) -> Int32 {
        let r = Int32(red * 255)
        let g = Int32(green * 255)
        let b = Int32(blue * 255)
        let a = Int32((1.0 - alpha) * 127) // libgd uses 0=opaque, 127=transparent
        return gdImageColorAllocateAlpha(image, r, g, b, a)
    }
}

// MARK: - Point and Size

public struct GDPoint: Sendable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public struct GDSize: Sendable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

// MARK: - Image

/// A wrapper around libgd image operations
public final class GDImage: @unchecked Sendable {
    private let image: gdImagePtr

    /// Create a new image with the specified dimensions
    public init?(width: Int, height: Int) {
        guard let img = gdImageCreateTrueColor(Int32(width), Int32(height)) else {
            return nil
        }
        self.image = img
        // Enable alpha blending
        gdImageAlphaBlending(image, 1)
        gdImageSaveAlpha(image, 1)
    }

    deinit {
        gdImageDestroy(image)
    }

    // MARK: - Drawing Operations

    /// Fill a rectangle with a color
    public func fillRectangle(topLeft: GDPoint, bottomRight: GDPoint, color: GDColor) {
        let c = color.toGDColor(in: image)
        gdImageFilledRectangle(
            image,
            Int32(topLeft.x),
            Int32(topLeft.y),
            Int32(bottomRight.x),
            Int32(bottomRight.y),
            c
        )
    }

    /// Draw a rectangle outline
    public func strokeRectangle(topLeft: GDPoint, bottomRight: GDPoint, color: GDColor) {
        let c = color.toGDColor(in: image)
        gdImageRectangle(
            image,
            Int32(topLeft.x),
            Int32(topLeft.y),
            Int32(bottomRight.x),
            Int32(bottomRight.y),
            c
        )
    }

    /// Fill an ellipse
    public func fillEllipse(center: GDPoint, size: GDSize, color: GDColor) {
        let c = color.toGDColor(in: image)
        gdImageFilledEllipse(
            image,
            Int32(center.x),
            Int32(center.y),
            Int32(size.width),
            Int32(size.height),
            c
        )
    }

    /// Draw a line
    public func drawLine(from: GDPoint, to: GDPoint, color: GDColor) {
        let c = color.toGDColor(in: image)
        gdImageLine(
            image,
            Int32(from.x),
            Int32(from.y),
            Int32(to.x),
            Int32(to.y),
            c
        )
    }

    /// Fill from a point with flood fill
    public func fill(from point: GDPoint, color: GDColor) {
        let c = color.toGDColor(in: image)
        gdImageFill(image, Int32(point.x), Int32(point.y), c)
    }

    /// Set a single pixel
    public func setPixel(at point: GDPoint, color: GDColor) {
        let c = color.toGDColor(in: image)
        gdImageSetPixel(image, Int32(point.x), Int32(point.y), c)
    }

    // MARK: - Export

    /// Export the image as PNG data
    public func exportPNG() -> Data? {
        var size: Int32 = 0
        guard let pngData = gdImagePngPtr(image, &size) else {
            return nil
        }
        defer { gdFree(pngData) }
        return Data(bytes: pngData, count: Int(size))
    }

    /// Export the image as JPEG data
    public func exportJPEG(quality: Int = 90) -> Data? {
        var size: Int32 = 0
        guard let jpegData = gdImageJpegPtr(image, &size, Int32(quality)) else {
            return nil
        }
        defer { gdFree(jpegData) }
        return Data(bytes: jpegData, count: Int(size))
    }
}

//
//  ImagePixelRBGA.swift
//  draw
//
//  Created by Anirudh Natarajan on 3/18/19.
//  Copyright © 2019 Anirudh Natarajan. All rights reserved.
//

import Foundation
import UIKit

struct Pixel {
    // structure that holds RGBA value
    
    var value: UInt32
    var red: UInt8 {
        get { return UInt8(value & 0xFF) }
        set { value = UInt32(newValue) | (value & 0xFFFFFF00) }
    }
    var green: UInt8 {
        get { return UInt8((value >> 8) & 0xFF) }
        set { value = (UInt32(newValue) << 8) | (value & 0xFFFF00FF) }
    }
    var blue: UInt8 {
        get { return UInt8((value >> 16) & 0xFF) }
        set { value = (UInt32(newValue) << 16) | (value & 0xFF00FFFF) }
    }
    var alpha: UInt8 {
        get { return UInt8((value >> 24) & 0xFF) }
        set { value = (UInt32(newValue) << 24) | (value & 0x00FFFFFF) }
    }
}

public struct ImagePixelRGBA {
    var pixels: UnsafeMutableBufferPointer<Pixel>
    var width: Int
    var height: Int
    
    init?(image: UIImage) {
        // convert image into 2D array of Pixels
        
        guard let cgImage = image.cgImage else { return nil }
        width = Int(image.size.width)
        height = Int(image.size.height)
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let imageData = UnsafeMutablePointer<Pixel>.allocate(capacity: width * height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        guard let imageContext = CGContext(data: imageData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else { return nil }
        imageContext.draw(cgImage, in: CGRect(origin: CGPoint(x: 0,y :0), size: image.size))
        pixels = UnsafeMutableBufferPointer<Pixel>(start: imageData, count: width * height)
    }
    
    public func toUIImage() -> UIImage? {
        // convert Pixels back into UIImage
        
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        let imageContext = CGContext(data: pixels.baseAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, releaseCallback: nil, releaseInfo: nil)
        guard let cgImage = imageContext!.makeImage() else {return nil}
        let image = UIImage(cgImage: cgImage)
        return image
    }
}

public func convertToBW(image: UIImage) -> ImagePixelRGBA {
    // iterate through Pixels and change desired ones black and everything else white
    
    let imageRGBA = ImagePixelRGBA(image: image)!
    
    for y in 0..<imageRGBA.height {
        for x in 0..<imageRGBA.width {
            let index = y * imageRGBA.width + x
            var pixel = imageRGBA.pixels[index]
            
            if (pixel.red > 205 && pixel.blue < 5 && pixel.green < 5) {
                pixel.red = 0
                pixel.blue = 0
                pixel.green = 0
            } else {
                pixel.red = 255
                pixel.blue = 255
                pixel.green = 255
            }
            
            imageRGBA.pixels[index] = pixel
        }
    }
    return imageRGBA
}

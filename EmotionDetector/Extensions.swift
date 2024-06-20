//
//  Extensions.swift
//  Test
//
//  Created by Afraz Siddiqui on 3/18/21.
//

import UIKit
import CoreML

extension UIImage {
    /// Resize image
    /// - Parameter size: Size to resize to
    /// - Returns: Resized image
    func resize(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// Create and return CoreVideo Pixel Buffer
    /// - Returns: Pixel Buffer
    func getCVPixelBuffer() -> CVPixelBuffer? {
        guard let image = cgImage else {
             return nil
        }
        let imageWidth = Int(image.width)
        let imageHeight = Int(image.height)

        let attributes : [NSObject:AnyObject] = [
            kCVPixelBufferCGImageCompatibilityKey : true as AnyObject,
            kCVPixelBufferCGBitmapContextCompatibilityKey : true as AnyObject
        ]

        var pxbuffer: CVPixelBuffer? = nil
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            imageWidth,
            imageHeight,
            kCVPixelFormatType_32ARGB,
            attributes as CFDictionary?,
            &pxbuffer
        )

        if let _pxbuffer = pxbuffer {
            let flags = CVPixelBufferLockFlags(rawValue: 0)
            CVPixelBufferLockBaseAddress(_pxbuffer, flags)
            let pxdata = CVPixelBufferGetBaseAddress(_pxbuffer)

            let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
            let context = CGContext(
                data: pxdata,
                width: imageWidth,
                height: imageHeight,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(_pxbuffer),
                space: rgbColorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
            )

            if let _context = context {
                _context.draw(
                    image,
                    in: CGRect.init(
                        x: 0,
                        y: 0,
                        width: imageWidth,
                        height: imageHeight
                    )
                )
            }
            else {
                CVPixelBufferUnlockBaseAddress(_pxbuffer, flags);
                return nil
            }

            CVPixelBufferUnlockBaseAddress(_pxbuffer, flags);
            return _pxbuffer;
        }

        return nil
    }
        func mlMultiArray(scale preprocessScale:Double=255, rBias preprocessRBias:Double=0, gBias preprocessGBias:Double=0, bBias preprocessBBias:Double=0) -> MLMultiArray {
            let imagePixel = self.getPixelRgb(scale: preprocessScale, rBias: preprocessRBias, gBias: preprocessGBias, bBias: preprocessBBias)
            let size = self.size
            let imagePointer : UnsafePointer<Double> = UnsafePointer(imagePixel)
            let mlArray = try! MLMultiArray(shape: [1, NSNumber(value: Float(size.width)), NSNumber(value: Float(size.height)), 3], dataType: MLMultiArrayDataType.double)
            mlArray.dataPointer.initializeMemory(as: Double.self, from: imagePointer, count: imagePixel.count)
            return mlArray
        }
        
        func mlMultiArrayGrayScale(scale preprocessScale:Double=255,bias preprocessBias:Double=0) -> MLMultiArray {
            let imagePixel = self.getPixelGrayScale(scale: preprocessScale, bias: preprocessBias)
            let size = self.size
            let imagePointer : UnsafePointer<Double> = UnsafePointer(imagePixel)
            let mlArray = try! MLMultiArray(shape: [0,  NSNumber(value: Float(size.width)), NSNumber(value: Float(size.height))], dataType: MLMultiArrayDataType.double)
            mlArray.dataPointer.initializeMemory(as: Double.self, from: imagePointer, count: imagePixel.count)
            return mlArray
        }

        func getPixelRgb(scale preprocessScale:Double=255, rBias preprocessRBias:Double=0, gBias preprocessGBias:Double=0, bBias preprocessBBias:Double=0) -> [Double]
        {
            guard let cgImage = self.cgImage else {
                return []
            }
            let bytesPerRow = cgImage.bytesPerRow
            let width = cgImage.width
            let height = cgImage.height
            let bytesPerPixel = 4
            let pixelData = cgImage.dataProvider!.data! as Data
            
            var r_buf : [Double] = []
            var g_buf : [Double] = []
            var b_buf : [Double] = []
            
            for j in 0..<height {
                for i in 0..<width {
                    let pixelInfo = bytesPerRow * j + i * bytesPerPixel
                    let r = Double(pixelData[pixelInfo])
                    let g = Double(pixelData[pixelInfo+1])
                    let b = Double(pixelData[pixelInfo+2])
                    r_buf.append(Double(r/preprocessScale)+preprocessRBias)
                    g_buf.append(Double(g/preprocessScale)+preprocessGBias)
                    b_buf.append(Double(b/preprocessScale)+preprocessBBias)
                }
            }
            return ((b_buf + g_buf) + r_buf)
        }
        
        func getPixelGrayScale(scale preprocessScale:Double=255, bias preprocessBias:Double=0) -> [Double]
        {
            guard let cgImage = self.cgImage else {
                return []
            }
            let bytesPerRow = cgImage.bytesPerRow
            let width = cgImage.width
            let height = cgImage.height
            let bytesPerPixel = 2
            let pixelData = cgImage.dataProvider!.data! as Data
            
            var buf : [Double] = []
            
            for j in 0..<height {
                for i in 0..<width {
                    let pixelInfo = bytesPerRow * j + i * bytesPerPixel
                    let v = Double(pixelData[pixelInfo])
                    buf.append(Double(v/preprocessScale)+preprocessBias)
                }
            }
            return buf
        }
}

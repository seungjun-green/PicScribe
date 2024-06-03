//
//  ModelManager.swift
//  Pic Scribe
//
//  Created by SeungJun Lee on 5/30/24.
//

import Foundation
import CoreML
import UIKit
import Foundation
import CoreML
import Accelerate

class ModelManager {
    
    var encoder: VIT_iOS_Encoder_v10
    var decoder: iOS_Decoder_V14
    let indexToWord: [Int: String]
    
    
    init() {
        
        let config = MLModelConfiguration()
        
        encoder = try! VIT_iOS_Encoder_v10(configuration: config)
        decoder = try! iOS_Decoder_V14(configuration: config)
        indexToWord = ModelManager.loadWordToIndexDictionary() ?? [:]
      
    }
    
    // Decoder
    private static func loadWordToIndexDictionary() -> [Int: String]? {
        
        guard let url = Bundle.main.url(forResource: "index_to_word", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        return try? JSONDecoder().decode([Int: String].self, from: data)
    }
    
    func convertToMLMultiArray(token_array: [[Int]]) -> MLMultiArray? {
        let rowCount = token_array.count
        let columnCount = token_array.first?.count ?? 0
        
        do {
            let multiArray = try MLMultiArray(shape: [NSNumber(value: rowCount), NSNumber(value: columnCount)], dataType: .int32)
            
            for (i, row) in token_array.enumerated() {
                for (j, value) in row.enumerated() {
                    multiArray[i * columnCount + j] = NSNumber(value: value)
                }
            }
            return multiArray
        } catch {
            print("Error creating MLMultiArray: \(error)")
            return nil
        }
    }
    
    
    func extractSlice(from logits: MLMultiArray, at index: Int) throws -> MLMultiArray {
        // Check dimensions
        guard logits.shape.count == 3,
              let dim1 = logits.shape[0] as? Int,
              let dim2 = logits.shape[1] as? Int,
              let dim3 = logits.shape[2] as? Int else {
            throw NSError(domain: "Invalid dimensions", code: -1, userInfo: nil)
        }
        
        // Make sure the index is within the second dimension's bounds
        guard index < dim2 && index >= 0 else {
            throw NSError(domain: "Index out of bounds", code: -1, userInfo: nil)
        }
        
        // Create a new MLMultiArray to store the slice
        let slice = try MLMultiArray(shape: [NSNumber(value: dim1), NSNumber(value: dim3)], dataType: logits.dataType)
        
        // Iterate over the required dimensions and fill the new MLMultiArray
        for j in 0..<dim1 {
            for k in 0..<dim3 {
                let originalIndex = [j, index, k] as [NSNumber]
                let newIndex = [j, k] as [NSNumber]
                slice[newIndex] = logits[originalIndex]
            }
        }
        
        return slice
    }
    
    func indexOfMaxValue(in array: MLMultiArray) -> Int {

        var maxIndex = 0
        var maxValue = Double(array[0].doubleValue)

        for i in 1..<array.count {
            let value = Double(array[i].doubleValue)
            if value > maxValue {
                maxValue = value
                maxIndex = i
            }
        }
        return maxIndex
    }

    
    func removeHashes(from word: String) -> String {
        return word.filter { $0 != "#" }
    }
    
    func constructString(data: [[Int]]) -> String {
        
        var result = ""
        
        let real_data = data[0]
        
        for index in real_data {
            
            let curr_word = indexToWord[index]!
            if curr_word != "[CLS]" && curr_word != "[SEP]" && curr_word != "[PAD]" {
                result += removeHashes(from: curr_word)
                result += " "
            }
            
        }
        return result
    }
    
    
    
    
    // Encoder
        
    func convertImage(image: UIImage) -> CVPixelBuffer? {
        
        let newSize = CGSize(width: 224.0, height: 224.0)
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        
        UIGraphicsEndImageContext()
        
        // convert to pixel buffer
        
        let attributes = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                  kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(newSize.width),
                                         Int(newSize.height),
                                         kCVPixelFormatType_32ARGB,
                                         attributes,
                                         &pixelBuffer)
        
        guard let createdPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(createdPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(createdPixelBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: Int(newSize.width),
                                      height: Int(newSize.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(createdPixelBuffer),
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        
        context.translateBy(x: 0, y: newSize.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        resizedImage.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(createdPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return createdPixelBuffer
    }
    
    func passEncoder(currentUIImage: UIImage?) -> MLMultiArray? {
        
        var encoder_output:  MLMultiArray?
        if let imageBuffer = convertImage(image: currentUIImage!) {
            do {
                encoder_output = try encoder.prediction(x_1: imageBuffer).var_1271
            } catch {
                print("somethign bad happend")
            }
        }
        
        return encoder_output
        
    }
    
}

import AVFoundation


public extension UIImage {
    /// Resize image while keeping the aspect ratio. Original image is not modified.
    /// - Parameters:
    ///   - width: A new width in pixels.
    ///   - height: A new height in pixels.
    /// - Returns: Resized image.
    func resize(_ width: Int, _ height: Int) -> UIImage {
        // Keep aspect ratio
        let maxSize = CGSize(width: width, height: height)

        let availableRect = AVFoundation.AVMakeRect(
            aspectRatio: self.size,
            insideRect: .init(origin: .zero, size: maxSize)
        )
        let targetSize = availableRect.size

        // Set scale of renderer so that 1pt == 1px
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        // Resize the image
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resized
    }
}

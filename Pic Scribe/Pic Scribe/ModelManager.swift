import Foundation
import CoreML
import UIKit

class ModelManager {
    
    var encoder: VIT_iOS_Encoder_v3
    var decoder: iOS_Decoder_V2
    let indexToWord: [Int: String]
    
    
    init() {
        
        let config = MLModelConfiguration()
        
        encoder = try! VIT_iOS_Encoder_v3(configuration: config)
        decoder = try! iOS_Decoder_V2(configuration: config)
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
    
    
    
    func generate(img_embeddings: MLMultiArray) -> String {
        
        var token_array = Array(repeating: 0, count: 32)
        token_array[0] = 101
        var token_MLarray = convertToMLMultiArray(token_array: [token_array])
        
        for i in 0...30 {
            do {
                let pred = try decoder.prediction(image_embeddings: img_embeddings, txt: token_MLarray!).var_240
                let next_token_id = pred[0]
                
                if next_token_id == 102 {
                    break
                }
                
                token_array[i+1] = Int(truncating: next_token_id)
                token_MLarray = convertToMLMultiArray(token_array: [token_array])
                
            } catch {
                print("Some error happened! ;(")
            }
            
            
        }
        
        print(token_array)
        let res = constructString(data: [token_array])
        print(res)
        
        return "Hello, World"
        
    }
    
    func constructString(data: [[Int]]) -> String {
        
        var result = ""
        
        let real_data = data[0]
        
        for index in real_data {
            
            let curr_word = indexToWord[index]!
            if curr_word != "[CLS]" && curr_word != "[SEP]" {
                result += curr_word
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

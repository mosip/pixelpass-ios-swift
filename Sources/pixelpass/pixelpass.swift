import Foundation
import base45_swift
import CoreImage
import Compression
#if canImport(UIKit)
import UIKit
 public class PixelPass {
    public init()
    {
        
    }
    public func decode(data: String) -> Data? {
        do {
            let base45DecodedData = try data.fromBase45()
            guard let decompressedData = Zlib().decompress(base45DecodedData) else {
                print("Error decompressing data")
                return nil
            }
            return decompressedData
        } catch {
            print("Error during Base45 decoding or decompression: \(error)")
            return nil
        }
    }
    
    public func encode(_ input: String) -> String? {
        if(input.elementsEqual(""))
        {
            return nil;
        }
        guard Zlib().compress(data:input,algorithm:COMPRESSION_ZLIB) != nil
        else {
            print("Error compressing data")
            return nil
        }
        let compressedData =  Zlib().compress(data:input,algorithm:COMPRESSION_ZLIB)
        guard let base45EncodedString = compressedData?.toBase45()
        else{
            print("Encoding error")
            return nil;
        }
        return base45EncodedString
    }
    
     public func generateQRCode(data: String, ecc: ECC = ECC.L, header: String = "") -> Data? {
         var qrText = encode(data)
         if qrText == nil {
             return nil
         } else {
             qrText! += header
         }
         let data = qrText?.data(using: String.Encoding.ascii)
         
         if let filter = CIFilter(name: "CIQRCodeGenerator") {
             filter.setValue(data, forKey: "inputMessage")
             filter.setValue(ecc.rawValue, forKey: "inputCorrectionLevel")
             
             if let qrImage = filter.outputImage {
                 let context = CIContext(options: nil)
                 if let cgImage = context.createCGImage(qrImage, from: qrImage.extent) {
                     let uiImage = UIImage(cgImage: cgImage)
                     return uiImage.pngData() // Get PNG data
                 }
             }
         }
         
         return nil
     }

    
}
#endif



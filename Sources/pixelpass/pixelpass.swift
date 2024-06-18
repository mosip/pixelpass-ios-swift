import Foundation
import base45_swift
import CoreImage
import Compression
import SwiftCBOR
import OSLog
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
                os_log("Error decompressing data",log: OSLog.default,type: OSLogType.error)
                return nil
            }
            //let byteArray = String(data:decompressedData,encoding: .ascii)?.hexaBytes
            let uintDecompressed = [UInt8](decompressedData)
            if let cborDecodedData = try? CBOR.decode(uintDecompressed) {
                if let cborDecodedDataJsonDictionary = cborDecodedData.converToJsonCompatibleFormat() as? [String: Any], JSONSerialization.isValidJSONObject(cborDecodedDataJsonDictionary) {
                    let jsonData = try JSONSerialization.data(
                        withJSONObject: cborDecodedDataJsonDictionary,
                        options: [.withoutEscapingSlashes]
                    )
                    return jsonData
                } else {
                    os_log("Decoded CBOR data is not a valid JSON object",log: OSLog.default,type: OSLogType.error)
                    return decompressedData                }
            } else {
                return decompressedData
            }
        } catch {
            os_log("Error during Base45 decoding, decompression, or CBOR decoding",log: OSLog.default,type: OSLogType.error)
            return nil
        }
    }
    
    
    public func generateQRData(_ input: String) -> String? {
        
        var compressedData: Data
        var base45EncodedString: String = ""
        
        guard !input.isEmpty else {
            return nil
        }
        
            if let jsonDataToVerify = input.data(using: .utf8), let jsonData = try? JSONSerialization.jsonObject(with: jsonDataToVerify) {
                let cborEncodableData = convertToCBOREncodableFormat(input: jsonData)
                let dataToCompress = cborEncodableData.encode()

                guard Zlib().compress(data:dataToCompress,algorithm:COMPRESSION_ZLIB) != nil
                        else {
                            os_log("Error compressing data",log: OSLog.default,type: OSLogType.error)
                            return nil
                        }
                
                compressedData = Zlib().compress(data: dataToCompress, algorithm:COMPRESSION_ZLIB)!
                let uintarray  = [UInt8](compressedData)
            } else {
                os_log("Data is not a valid JSON",log: OSLog.default,type: OSLogType.error)
                
                guard Zlib().compress(data:input,algorithm:COMPRESSION_ZLIB) != nil
                        else {
                            os_log("Error compressing data",log: OSLog.default,type: OSLogType.error)
                            return nil
                        }
                
                compressedData = Zlib().compress(data: input, algorithm:COMPRESSION_ZLIB)!
            }
        base45EncodedString = compressedData.toBase45()
        return base45EncodedString
    }
    
    public func generateQRCode(data: String, ecc: ECC = ECC.L, header: String = "") -> Data? {
        var qrText = generateQRData(data)
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



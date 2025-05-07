import Foundation
import base45_swift
import CoreImage
import Compression
import SwiftCBOR
import OSLog
import ZIPFoundation
#if canImport(UIKit)
import UIKit

extension Array where Element == UInt8 {
    func toHexString() -> String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
}


public class PixelPass {
    public init()
    {
        
    }
    
    public func decodeBinary(data: [UInt8]) throws -> String? {
        clearTemporaryDirectory()
        
        let encodedData = Data(data)
        guard String(decoding: encodedData, as: UTF8.self).hasPrefix(Constants.zipHeader) else {
            throw decodeByteArrayError.UnknownBinaryFileTypeException
        }

        let tempZipFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp.zip")
        try encodedData.write(to: tempZipFileURL)

        guard let archive = Archive(url: tempZipFileURL, accessMode: .read),
              let entry = archive[Constants.defaultZipFileName] else {
            os_log("Error accessing zip file or missing entry", log: OSLog.default, type: .error)
            return nil
        }

        var extractedData = Data()
        let _ = try archive.extract(entry) { extractedData.append($0) }

        return String(data: extractedData, encoding: .utf8)
    }

    public func decode(data: String) -> Data? {
        do {
            let base45DecodedData = try data.fromBase45()
            guard let decompressedData = Zlib().decompress(base45DecodedData) else {
                os_log("Error decompressing data",log: OSLog.default,type: OSLogType.error)
                return nil
            }
            let byteArray = [UInt8](decompressedData)
            if let cborDecodedData = try? CBOR.decode(byteArray) {
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
            let cborEncodedData = cborEncodableData.encode()
            
            guard Zlib().compress(data:cborEncodedData,algorithm:COMPRESSION_ZLIB) != nil
            else {
                os_log("Error compressing data",log: OSLog.default,type: OSLogType.error)
                return nil
            }
            
            compressedData = Zlib().compress(data: cborEncodedData, algorithm:COMPRESSION_ZLIB)!
            
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
    
    public func getMappedData(stringData: String, mapper: [String:String], cborEnable : Bool = false) -> String {
        let jsonData = stringData.data(using: .utf8)!
        let mappedJSON = translateToJSON(jsonData: jsonData, mapper: mapper)
        do {
            if !cborEnable{
                let decoded =  try JSONSerialization.data(withJSONObject: mappedJSON, options: [])
                if let str = String(data: decoded, encoding: .utf8) {
                    return str
                }
            }
        }catch {
            os_log("Error: %{PUBLIC}@", log: OSLog.default, type: .error, error.localizedDescription)
            return ""
        }
        
        let cborEncodableData = convertToCBOREncodableFormat(input: mappedJSON)
        return cborEncodableData.encode().toHexString()
    }
    
    public func decodeMappedData(stringData: String, mapper: [String: String]) -> [String: String]? {
        do {
            let data = [UInt8](Data(hexString: stringData) ?? Data())
            if !data.isEmpty {
                let cborDecodedData = try? CBOR.decode(data)
                let cborDecodedDataJsonDictionary = cborDecodedData?.converToJsonCompatibleFormat()
                
                let jsonData = try JSONSerialization.data(
                    withJSONObject: cborDecodedDataJsonDictionary!,
                    options: [.withoutEscapingSlashes]
                )
                return translateToJSON(jsonData: jsonData, mapper: mapper)
            }
            else{
                let jsonData = stringData.data(using: .utf8)!
                return translateToJSON(jsonData: jsonData, mapper: mapper)
            }
        } catch {
            os_log("Error: %{PUBLIC}@", log: OSLog.default, type: .error, error.localizedDescription)
            return nil
        }
    }
    
    func translateToJSON(jsonData: Data, mapper: [String: String]) -> [String: String] {
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                return [:]
            }
            var result = [String: String]()
            for (key, value) in jsonObject {
                let mappedKey = mapper[key] ?? key
                result[mappedKey] = value as? String
            }
            return result
        } catch {
            print("Error decoding JSON data: \(error)")
            return [:]
        }
    }
    public func toJson(base64UrlEncodedCborEncodedString:String) throws -> Any {
        do{
            guard let decodedBase64Data = Data(base64EncodedURLSafe: base64UrlEncodedCborEncodedString) else {
                os_log("Invalid base64 URL string provided",log: OSLog.default, type: .error)
                throw decodeByteArrayError.customError(description: "Error while base64 url decoding the data")
            }
            
            let inputToCBORDecode = Array(decodedBase64Data)
            if let cborDecodedData = try? CBOR.decode(inputToCBORDecode) {
                if let cborInJSON = cborDecodedData.converToJsonCompatibleFormat() as? [String: Any], JSONSerialization.isValidJSONObject(cborInJSON) {
                    return cborInJSON
                } else {
                    os_log("Decoded CBOR data is not a valid JSON object",log: .default,type: .error)
                    throw decodeError.customError(description: "CBOR data is not a valid JSON object")            }
            } else {
                os_log("Error while CBOR decoding the data",log: .default,type: .error)
                throw decodeError.customError(description: "CBOR decoding failed")
            }
        }
        catch let error {
            os_log("error occurred while parsing  data - %{PUBLIC}@",log: .default, type: .error, error.localizedDescription)
            throw decodeByteArrayError.customError(description: "error occurred while parsing  data - \(error.localizedDescription)")
        }
    }
}
#endif

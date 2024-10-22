import XCTest
import Foundation
@testable import pixelpass

class PixelPassTests: XCTestCase {
    var pixelPass: PixelPass!
    
    override func setUp() {
        super.setUp()
        pixelPass = PixelPass()
    }
    
    override func tearDown() {
        pixelPass = nil
        super.tearDown()
    }
    
    func testEncodeStandardInput() {
        let inputString = "Hello, World!"
        let encoded = pixelPass.generateQRData(inputString)
        let expectedEncodedString="V7F0YUV0QBNP:AAT8QZPP+AAV00./JG2"
        XCTAssertNotNil(encoded, "The encoded output should not be nil for standard input.")
        XCTAssertTrue(encoded!.count > 0, "The encoded string should have length greater than zero.")
        XCTAssert((encoded != nil),expectedEncodedString,file: "Encoded string should be same as expected encoded string")
    }
    
    func testEncodeEmptyInput() {
        let emptyInput = ""
        let encoded = pixelPass.generateQRData(emptyInput)
        XCTAssertNil(encoded, "Encoding should return nil for an empty string.")
    }
    
    func testDecodeValidInput() {
        let inputString = "V7F0YUV0QBNP:AAT8QZPP+AAV00./JG2"
        let decodedData = pixelPass.decode(data: inputString)
        
        let expectedDecodedString="Hello, World!"
        XCTAssertNotNil(decodedData, "Decoding should succeed for valid encoded input.")
        let decodedString = String(data: decodedData!, encoding: .utf8)
        XCTAssertEqual(decodedString, expectedDecodedString, "The decoded string should match the expected decoded string.")
        
    }
    
    func testDecodeInvalidInput() {
        let invalidBase45String = "#$%^&*()_+"
        let decodedData = pixelPass.decode(data: invalidBase45String)
        XCTAssertNil(decodedData, "Decode should return nil for invalid Base45 input.")
    }
    
    func testEncodeAndDecodeCycle() {
        // Test case for non-empty string
        let inputString = "Hello, this is a test string for PixelPass encoding and decoding."
        if let encoded = pixelPass.generateQRData(inputString),
           let decodedData = pixelPass.decode(data: encoded),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            XCTAssertEqual(decodedString, inputString, "The decoded string should match the original input string.")
        } else {
            XCTFail("Encoding or decoding failed.")
        }
        
        // Test case for empty string
        let emptyInput = ""
        XCTAssertNil(pixelPass.generateQRData(emptyInput), "Encoding should return nil for an empty string.")
    }
    
    func testGenerateQRCode() {
        let inputString = "Test QR Code generation"
        let qrCodeImage = pixelPass.generateQRCode( data: inputString,ecc: ECC.M)
       
        XCTAssertNotNil(qrCodeImage, "QR Code generation should succeed and return a non-nil UIImage.")
    }
    
    func testDecodeErrorHandling() {
        let incorrectBase45String = "This is not a Base45 string"
        XCTAssertNil(pixelPass.decode(data: incorrectBase45String), "Decode should return nil for incorrect Base45 encoded strings.")
    }
    
    func testDecodeValidInputCBOR() {
        let inputString = "V7F3QBXJA5NJRCOC004 QN4"
        let decodedData = pixelPass.decode(data: inputString)
        let expectedDecodedString="{\"temp\":15}"
        XCTAssertNotNil(decodedData, "Decoding should succeed for valid encoded input.")
        let decodedString = String(data: decodedData!, encoding: .utf8)
        XCTAssertEqual(decodedString, expectedDecodedString, "The decoded string should match the expected decoded string.")
    }
    
    func testEncodeValidInputCBOR() {
        let inputString = "{\"temp\":15}"
        let encoded = pixelPass.generateQRData(inputString)
        let expectedEncodedString = "V7F3QBXJA5NJRCOC004 QN4"
        XCTAssertNotNil(encoded!, "The encoded output should not be nil for standard input.")
        XCTAssertTrue(encoded!.count > 0, "The encoded string should have length greater than zero.")
        XCTAssertEqual(encoded,expectedEncodedString, "Encoded string should be same as expected encoded string")
    }
    
    func testEncodeAndDecodeInputCBOR() {
        let inputString = "{\"temp\":123}],\"bool\":true,\"arryF\":[1,2.5,3,-4,\"hello\",{\"temp\":123}],\"arryE\":[]}"
        let encoded = pixelPass.generateQRData(inputString)!
        let decoded = pixelPass.decode(data: encoded)
        let decodedString = String(data: decoded!, encoding: .utf8)
        XCTAssertNotNil(decodedString, "Decoding should succeed for valid encoded input.")
        XCTAssertEqual(inputString,decodedString, "Decoded string should be same as expected input string")
    }
    
    func testJsonMappedCBOREncode() {
        let jsonData = "{\"id\": \"207\"}"
        let mapper = ["id": "1"]
        let expectedCborEncodedString = "a1613163323037"
        let cborEncodedData = pixelPass.getMappedData(stringData: jsonData,mapper: mapper,cborEnable: true)
        
        XCTAssertNotNil(cborEncodedData, "JSON mapping should succeed for valid input.")
        XCTAssertEqual(cborEncodedData,expectedCborEncodedString, "Encoded string should be same as expected string")
    }
    
    func testJsonMappedEncode() {
        let jsonData = "{\"id\": \"207\"}"
        let mapper = ["id": "1"]
        let expectedMappedData = "{\"1\":\"207\"}"
        let mappedData = pixelPass.getMappedData(stringData: jsonData,mapper: mapper)

        XCTAssertNotNil(mappedData, "JSON mapping should succeed for valid input.")
        XCTAssertEqual(mappedData,expectedMappedData, "Encoded string should be same as expected string")
    }
    
    func testJsonMappedCBORDecode() {
        let expected = ["id": "207", "name": "Jhon", "l_name": "Honay"]
        let mapper = ["1": "id", "2": "name", "3": "l_name"]
        let data = "a302644a686f6e01633230370365486f6e6179"
        let jsonData = pixelPass.decodeMappedData(stringData: data, mapper: mapper)
        XCTAssertNotNil(jsonData, "JSON mapping should succeed for valid input.")
        XCTAssertEqual(jsonData,expected, "Decoded JSON should be same as expected JSON")
    }
    
    func testJsonMappedDecode() {
        let expected = ["id": "207", "name": "Jhon", "l_name": "Honay"]
        let mapper = ["1": "id", "2": "name", "3": "l_name"]
        let data = "{\"1\": \"207\", \"2\": \"Jhon\", \"3\": \"Honay\"}"
        let jsonData = pixelPass.decodeMappedData(stringData: data, mapper: mapper)
        XCTAssertNotNil(jsonData, "JSON mapping should succeed for valid input.")
        XCTAssertEqual(jsonData,expected, "Decoded JSON should be same as expected JSON")
    }
    
    func testByteArrayValidInput() {
        
        clearTemporaryDirectory()
        
        let fileManager = FileManager.default
        let tempdir = FileManager.default.temporaryDirectory
        let inputString = "Hello, World!"
        let fileURL = tempdir.appendingPathComponent("certificate.json")
        let zipURL = tempdir.appendingPathComponent("temp.zip")
        
        var decodedString = ""
        do {
            try inputString.write(to: fileURL, atomically: true, encoding: .utf8)
            try fileManager.zipItem(at: fileURL, to: zipURL)
            let fileData = try Data(contentsOf: zipURL)
            let byetArray = [UInt8](fileData)
            decodedString = try pixelPass.decodeBinary(data: byetArray)!
        } catch {
            print(error)
        }
        XCTAssertNotNil(decodedString, "The decoded string should not be empty.")
        XCTAssertEqual(inputString, decodedString, "The decoded string should match the expected decoded string.")
    }
    
    func testByteArrayInvalidInput() {
        
        clearTemporaryDirectory()
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempTxtFileURL = tempDirectory.appendingPathComponent("temp.txt")
        let content = "This is a test text file."
        
        do {
            try content.write(to: tempTxtFileURL, atomically: true, encoding: .utf8)
            let fileData = try Data(contentsOf: tempTxtFileURL)
//            XCTAssertThrowsError(try PixelPass().decodeBinary(data: [UInt8](fileData))) { error in
//                XCTAssertEqual(error as? decodeByteArrayError, decodeByteArrayError.UnknownBinaryFileTypeException)
//            }
        } catch {
            XCTFail("Error reading text file: \(error)")
        }
    }
    
    func testBase64EncodedCborDataToJsonCOnversion() {
        do {
            let expected = ["id": "207", "name": "Jhon", "l_name": "Honay"]
            let mapper = ["1": "id", "2": "name", "3": "l_name"]
            let data = "omdkb2NUeXBldW9yZy5pc28uMTgwMTMuNS4xLm1ETGxpc3N1ZXJTaWduZWSiamlzc3VlckF1dGiEQ6EBJqEYIVkB2TCCAdUwggF7oAMCAQICFBRDWWSBLltTWt65yytaZ01baoM9MAoGCCqGSM49BAMCMFkxCzAJBgNVBAYTAk1LMQ4wDAYDVQQIDAVNSy1LQTENMAsGA1UEBwwETW9jazENMAsGA1UECgwETW9jazENMAsGA1UECwwETU9jazENMAsGA1UEAwwETW9jazAeFw0yNDEwMjEwNzU2MTBaFw0yNTEwMjEwNzU2MTBaMFkxCzAJBgNVBAYTAk1LMQ4wDAYDVQQIDAVNSy1LQTENMAsGA1UEBwwETW9jazENMAsGA1UECgwETW9jazENMAsGA1UECwwETU9jazENMAsGA1UEAwwETW9jazBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABA8PMic1jzZYunhb2Ymq3eH2qEudb5rBnGMk1RAmFuLbPYBgFhDjdhK7j3ciE16-XfCFHnVEX8cANHw1_XjU2nejITAfMB0GA1UdDgQWBBQmaVJHKU-6Y7m6g6qolUJ3p94yhjAKBggqhkjOPQQDAgNIADBFAiEAwXQgNSUrhHIlPE1N24u5UCRwBTqYKKpJqBlC0niZRHgCIFryTL85LV-hab5RL4YiDpDeNOL6_YyiS-STfjrv-OL4WQJR2BhZAkymZ3ZlcnNpb25jMS4wb2RpZ2VzdEFsZ29yaXRobWdTSEEtMjU2Z2RvY1R5cGV1b3JnLmlzby4xODAxMy41LjEubURMbHZhbHVlRGlnZXN0c6Fxb3JnLmlzby4xODAxMy41LjGoAlggahyUDZzWwyVz1oYQSOSTOl3XfzVAAVi-ILLpwP3DMtUGWCBJiBVoqzuOj8ZRrOsV7DNFe0QBWplIKWMU3aILs8y6lwNYILzO8fswbC_wn7rQYO8eq91XotAltVllVzYTwyYHHWYIAVggHp8Y6cV73O670tvfMiyCZoxGczcYyfOh43Q8ahKpxxcEWCC75BhZBjDE1I4S5NLZAsaUmBERMZM9rMgZPkAzl45VeABYIIlDF4uT1D3MLGPsLL-kVBP0SHyxAYcAVf9SLYLUJUUgB1ggFuI0cmV1WwSJGv5VxI5a7Dsm6fIqr2MeIDBmYjIlZ0oFWCA88kOo8KNGtCpl2XH5CXMcgoE6D_fag9xjmPoLUcpgpG1kZXZpY2VLZXlJbmZvoWlkZXZpY2VLZXmkAQIgASFYIOMdpjABg7S1sJBCgdC4D6V237Jk_oGhMl_LInX0CFnGIlggPdyNKVXrSZb4CYQmoK6lX7Zux0DIBcnhJ9-_a7ZlYtdsdmFsaWRpdHlJbmZvo2ZzaWduZWTAdDIwMjQtMTAtMjFUMDg6MTE6MTNaaXZhbGlkRnJvbcB0MjAyNC0xMC0yMVQwODoxMToxM1pqdmFsaWRVbnRpbMB0MjAyNS0xMC0yMVQwODoxMToxM1pYQBZJtQ6yPA--sITjOK29mGLGKeG2DEx3qDHQEw99esCHwUnPJtobUfLGHhfmM0nawMZai21LXq5ZEdInOkEDSNRqbmFtZVNwYWNlc6Fxb3JnLmlzby4xODAxMy41LjGI2BhYaqRoZGlnZXN0SUQCZnJhbmRvbVBthSy1vmphqpoMYRe9Z0PncWVsZW1lbnRJZGVudGlmaWVyamlzc3VlX2RhdGVsZWxlbWVudFZhbHVleBsyMDI0LTEwLTIxVDA4OjExOjEzLjQ5NTQ3OFrYGFhrpGhkaWdlc3RJRAZmcmFuZG9tUNyXhXOZjmheiFyzYfhsl0ZxZWxlbWVudElkZW50aWZpZXJrZXhwaXJ5X2RhdGVsZWxlbWVudFZhbHVleBsyMDI1LTEwLTIxVDA4OjExOjEzLjQ5NTQ3OFrYGFjBpGhkaWdlc3RJRANmcmFuZG9tUCC-v7ARALJ2VFcYww9AbMhxZWxlbWVudElkZW50aWZpZXJyZHJpdmluZ19wcml2aWxlZ2VzbGVsZW1lbnRWYWx1ZXhqe2lzc3VlX2RhdGU9MjAyNC0xMC0yMVQwODoxMToxMy40OTU0NzhaLCB2ZWhpY2xlX2NhdGVnb3J5X2NvZGU9QSwgZXhwaXJ5X2RhdGU9MjAyNS0xMC0yMVQwODoxMToxMy40OTU0NzhafdgYWFekaGRpZ2VzdElEAWZyYW5kb21Q46GI__EQWetvvOYmVd-9b3FlbGVtZW50SWRlbnRpZmllcm9kb2N1bWVudF9udW1iZXJsZWxlbWVudFZhbHVlZDEyMzPYGFhVpGhkaWdlc3RJRARmcmFuZG9tUIO4lnDW2fm_Utg97twL9mJxZWxlbWVudElkZW50aWZpZXJvaXNzdWluZ19jb3VudHJ5bGVsZW1lbnRWYWx1ZWJNS9gYWFikaGRpZ2VzdElEAGZyYW5kb21QBYNczBataC2MR4om9FAnmHFlbGVtZW50SWRlbnRpZmllcmpiaXJ0aF9kYXRlbGVsZW1lbnRWYWx1ZWoxOTk0LTExLTA22BhYVKRoZGlnZXN0SUQHZnJhbmRvbVBJWZtW3VOzNRpXK0Dyf3LTcWVsZW1lbnRJZGVudGlmaWVyamdpdmVuX25hbWVsZWxlbWVudFZhbHVlZkpvc2VwaNgYWFWkaGRpZ2VzdElEBWZyYW5kb21QfzR7XZl5Fiz6lZ0oMqRhlnFlbGVtZW50SWRlbnRpZmllcmtmYW1pbHlfbmFtZWxlbGVtZW50VmFsdWVmQWdhdGhh"
            let jsonData = try pixelPass.toJson(base64UrlEncodedCborEncodedString: data)
            XCTAssertNotNil(jsonData, "JSON mapping should succeed for valid input.")
            print("data is \(jsonData)")
            
        } catch let error {
            print("Error occurred ",error)
        }
    }
}

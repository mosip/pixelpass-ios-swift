import XCTest
@testable import pixelpass

extension Array where Element == UInt8 {
    func toHexString() -> String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
}

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
        let jsonData = ["id": "207"]
        let mapper = ["id": "1"]
        let expectedCborEncodedString = "a1613163323037"
        let cborEncodedData = pixelPass.getMappedCborData(jsonData: jsonData,mapper: mapper).toHexString()
        
        let expectedDecodedData = ["1":"207"]
        let decodedCborData = pixelPass.decodeMappedCborData(cborEncodedString: expectedCborEncodedString, mapper: mapper)
        
        XCTAssertNotNil(cborEncodedData, "JSON mapping should succeed for valid input.")
        XCTAssertEqual(cborEncodedData,expectedCborEncodedString, "Encoded string should be same as expected string")
        XCTAssertEqual(expectedDecodedData,decodedCborData, "Encoded string should be same as expected string")
    }
    
    func testJsonMappedCBORDecode() {
        let expected = ["id": "207", "name": "Jhon", "l_name": "Honay"]
        let mapper = ["1": "id", "2": "name", "3": "l_name"]
        let data = "a302644a686f6e01633230370365486f6e6179"
        let jsonData = pixelPass.decodeMappedCborData(cborEncodedString: data, mapper: mapper)
        XCTAssertNotNil(jsonData, "JSON mapping should succeed for valid input.")
        XCTAssertEqual(jsonData,expected, "Decoded JSON should be same as expected JSON")
    }
}

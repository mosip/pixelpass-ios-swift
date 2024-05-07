import XCTest
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
        let encoded = pixelPass.encode(inputString)
        let expectedEncodedString="V7F0YUV0QBNP:AAT8QZPP+AAV00./JG2"
        XCTAssertNotNil(encoded, "The encoded output should not be nil for standard input.")
        XCTAssertTrue(encoded!.count > 0, "The encoded string should have length greater than zero.")
        XCTAssert((encoded != nil),expectedEncodedString,file: "Encoded string should be same as expected encoded string")
    }
    
    func testEncodeEmptyInput() {
        let emptyInput = ""
        let encoded = pixelPass.encode(emptyInput)
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
        if let encoded = pixelPass.encode(inputString),
           let decodedData = pixelPass.decode(data: encoded),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            XCTAssertEqual(decodedString, inputString, "The decoded string should match the original input string.")
        } else {
            XCTFail("Encoding or decoding failed.")
        }
        
        // Test case for empty string
        let emptyInput = ""
        XCTAssertNil(pixelPass.encode(emptyInput), "Encoding should return nil for an empty string.")
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
}

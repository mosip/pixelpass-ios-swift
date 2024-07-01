
# PixelPass

PixelPass is a Swift library designed for encoding, decoding, and generating QR codes. It leverages Base45 encoding and Zlib compression to manage data efficiently, making it particularly useful for mobile applications where data size and integrity are crucial.

## Features

- **Base45 Encoding/Decoding**: Encode and decode strings using Base45.
- **Zlib Compression/Decompression**: Compress and decompress data efficiently.
- **QR Code Generation**: Create QR codes from strings with customizable error correction levels.

## Installation

To include PixelPass in your Swift project:
- Clone the PixelPass library locally.
- Create a new Swift project.
- Add package dependency: PixelPass


## API Reference

### `generateQRCode(data: String, ecc: ECC = .L, header: String = "")`

Generates a QR code from the provided string. The method first compresses and encodes the input string, then creates a QR code with an optional error correction level and header. The QR code is returned as PNG data.

**Parameters:**
- `data`: The string to encode and generate a QR code from.
- `ecc`: Error correction level with a default of `.L`.
- `header`: A string prepended to the encoded data, optional.

**Returns:**
- Data representing the QR code image in PNG format, or `nil` if an error occurs.

**Example Usage:**

```swift
let pixelPass = PixelPass()
if let qrCodeData = pixelPass.generateQRCode(data: "Hello, World!", ecc: .M, header: "HDR") {
    // Use qrCodeData in your application (e.g., display in an ImageView)
}
```
### `generateQRData(input: String) -> String?`

Generates a Base45 encoded string from the provided input after compressing it using Zlib. This method handles the compression and encoding of the input string.

**Parameters:**
- `input`: The string to compress and encode.

**Returns:**
- The Base45 encoded string, or `nil` if an error occurs.

**Example Usage:**

```swift
let pixelPass = PixelPass()
if let encodedString = pixelPass.generateQRData("Hello, World!") {
    print(encodedString)
} else {
    print("Failed to generate QR data.")
}
```

### `decode(data: String) -> Data?`

Decodes a given Base45 encoded string which is expected to be Zlib compressed. This method handles the decompression and Base45 decoding of the input string.

**Parameters:**
- `data`: The Base45 encoded and Zlib compressed string.

**Returns:**
- The decompressed and decoded data as a `Data` object, or `nil` if an error occurs.

**Example Usage:**

```swift
let pixelPass = PixelPass()
if let decodedData = pixelPass.decode("EncodedStringHere") {
    print(String(data: decodedData, encoding: .utf8) ?? "Failed to decode.")
}
```

### `getMappedCborData(jsonData: [String:String], mapper: [String:String]) -> [UInt8]`

Maps the given JSON data with mapper provided and encodeds to CBOR.

**Parameters:**
- `jsonData`: The JSON data to be mapped with mapper and encoded to CBOR.
- `mapper`: The MAP of replacement keys for JSON to re-map the given JSON keys.

**Returns:**
- The CBOR encoded HEX array as a `[UInt8]` object.

**Example Usage:**

```swift
let pixelPass = PixelPass()
let jsonData = ["id": "207"]
let mapper = ["id": "1"]
let cborEncodedData = pixelPass.getMappedCborData(jsonData: jsonData,mapper: mapper).toHexString()
print(String(data: cborEncodedData, encoding: .utf8))
```


### `decodeMappedCborData(cborEncodedString: String, mapper: [String: String]) -> [String: String]?`

Decodes the given string data from CBOR and re-maps with mapper provided.

**Parameters:**
- `cborEncodedString`: The CBOR endoded string data to be decoded.
- `mapper`: The MAP of replacement keys for JSON to re-map the given JSON keys.

**Returns:**
- The JSON data as a `[String: String]?` object, or `nil` if an error occurs.

**Example Usage:**

```swift
let pixelPass = PixelPass()
let mapper = ["1": "id", "2": "name", "3": "l_name"]
let data = "a302644a686f6e01633230370365486f6e6179"
if let decodedData = pixelPass.decodeMappedCborData(cborEncodedString: data, mapper: mapper) {
    print(String(data: decodedData, encoding: .utf8) ?? "Failed to decode.")
}
```


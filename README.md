
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



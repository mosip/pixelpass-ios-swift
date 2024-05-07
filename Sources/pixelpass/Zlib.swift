import Foundation
import Compression

class Zlib {
    
    

    func decompress(_ data: Data) -> Data? {
        if data.count <= Constants.headerSize {
            return .init()
        }
        let size = Constants.initialBufferSizeMultiplier * data.count + Constants.extraBufferSize
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        defer {
            buffer.deallocate()
        }

        let result = data.subdata(in: Constants.headerSize ..< data.count).withUnsafeBytes {
            let read = compression_decode_buffer(buffer, size, $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1), data.count - Constants.headerSize, nil, COMPRESSION_ZLIB)
            return Data(bytes: buffer, count: read)
        } as Data

        return result
    }

    func compress(data: String, algorithm: compression_algorithm = COMPRESSION_ZLIB) -> Data? {
        var sourceBuffer = Array(data.utf8)
        let destinationBufferSize = sourceBuffer.count + (sourceBuffer.count / Constants.compressionRatioDenominator) + Constants.compressionOverhead
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationBufferSize)
        defer {
            destinationBuffer.deallocate()
        }

        let compressedSize = compression_encode_buffer(destinationBuffer, destinationBufferSize,
                                                       &sourceBuffer, sourceBuffer.count,
                                                       nil,
                                                       algorithm)
        if compressedSize == 0 {
            return nil
        }

        var compressedData = Data(Constants.compressionHeader)
        compressedData.append(Data(bytes: destinationBuffer, count: compressedSize))
        let checksum = Zlib.calculateAdler32(for: Data(sourceBuffer))
        var bigEndianChecksum = checksum.bigEndian
        compressedData.append(Data(bytes: &bigEndianChecksum, count:Constants.checksumSize))

        return compressedData
    }

    private static func calculateAdler32(for data: Data) -> UInt32 {
        var a: UInt32 = 1, b: UInt32 = 0
        for byte in data {
            a = (a + UInt32(byte)) % Constants.adlerBase
            b = (b + a) % Constants.adlerBase
        }

        return (b << 16) | a
    }
}

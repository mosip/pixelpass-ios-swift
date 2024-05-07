import Foundation
 struct Constants{
     static let headerSize = 2
     static let initialBufferSizeMultiplier = 4
     static let extraBufferSize = 8 * 1024
    
     static let compressionHeader: [UInt8] = [0x78, 0x01]
     static let checksumSize = MemoryLayout<UInt32>.size
     static let compressionOverhead = 12
     static let compressionRatioDenominator = 1000
    
     static let adlerBase: UInt32 = 65521
}

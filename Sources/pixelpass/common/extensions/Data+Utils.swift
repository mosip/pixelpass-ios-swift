import Foundation

extension Data {
    init?(base64EncodedURLSafe string: String, options: Base64DecodingOptions = []) {
        var string =
        string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let remainder = string.count % 4
               if remainder > 0 {
                   string.append(String(repeating: "=", count: 4 - remainder))
               }
        
        self.init(base64Encoded: string, options: options)
    }
    
    init?(hexString: String) {
        let hexString = hexString.hasPrefix("0x") || hexString.hasPrefix("0X") ? String(hexString.dropFirst(2)) : hexString
        guard hexString.count % 2 == 0 else { return nil }
        
        var data = Data(capacity: hexString.count / 2)
        for i in stride(from: 0, to: hexString.count, by: 2) {
            let byteString = hexString.index(hexString.startIndex, offsetBy: i)..<hexString.index(hexString.startIndex, offsetBy: i+2)
            guard let byte = UInt8(hexString[byteString], radix: 16) else { return nil }
            data.append(byte)
        }
        
        self = data
    }
}

import Foundation
import SwiftCBOR
import OSLog

extension Data {
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

extension CBOR {
    func converToJsonCompatibleFormat() -> Any {
        switch self {
        case .array(let array):
            return array.map {
                $0.converToJsonCompatibleFormat()
            }
        case .map(let map):
            var dict = [String: Any]()
            for (key, value) in map {
                let keyString: String
                switch key {
                case let .utf8String(s):
                    keyString = s
                case let .unsignedInt(unsignedInt):
                    keyString = String(unsignedInt)
                case let .double(double):
                    keyString = String(double)
                default:
                    keyString = String(describing: key)
                    os_log("Non-standard key type encountered, converting to string: %{PUBLIC}@", log: OSLog.default, type: .error, keyString)
                }
                dict[keyString] = value.converToJsonCompatibleFormat()
            }
            return dict
        case .utf8String(let string):
            return string
        case .byteString(let data):
            return Data(data).base64EncodedString()
        case .boolean(let bool):
            return bool
        case .double(let double):
            return double
        case .unsignedInt(let unsignedInt):
            return unsignedInt
        case .null:
            return NSNull()
        default:
            os_log("Unhandled or non-JSON-compatible CBOR type encountered: %{PUBLIC}@", log: OSLog.default, type: .error, String(describing: self))
            return NSNull()
        }
    }
}

func convertToCBOREncodableFormat(input: Any) -> CBOR? {
    switch input {
    case let array as [Any]:
        return .array(array.compactMap { convertToCBOREncodableFormat(input: $0) })

    case let dict as [String: Any]:
        var map = [CBOR: CBOR]()
        for (key, value) in dict {
            if let keyCbor = convertToCBOREncodableFormat(input: key),
               let valueCbor = convertToCBOREncodableFormat(input: value) {
                map[keyCbor] = valueCbor
            } else {
                os_log("Non-encodable key or value encountered: %{PUBLIC}@", log: OSLog.default, type: .error, key)
            }
        }
        return .map(map)
        
    case let string as String:
        return .utf8String(string)
        
    case let base64String as String:
        let data = Data(base64Encoded: base64String)
        return .byteString([UInt8](data!))
        
    case let unsignedInt as UInt64:
        return .unsignedInt(unsignedInt)
        
    case let bool as Bool:
        return .boolean(bool)
        
    case let double as Double:
        return .double(double)
        
    case is NSNull:
        return .null
        
    default:
        os_log("Unhandled or non-encodable JSON type encountered: %{PUBLIC}@", log: OSLog.default, type: .error, String(describing: input))
        return nil
    }
}

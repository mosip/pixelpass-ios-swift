import Foundation
import SwiftCBOR
import OSLog

extension StringProtocol {
    var hexaData: Data { .init(hexa) }
    var hexaBytes: [UInt8] { .init(hexa) }
    private var hexa: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            guard startIndex < self.endIndex else { return nil }
            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}

extension CBOR {
    func converToJsonCompatibleFormat() -> Any { // negative int?
        switch self {
        case .array(let array):
            return array.map {
                $0.converToJsonCompatibleFormat()
            }
        case .map(let map):
            var dict = [String: Any]() // preserve order needed?
            for (key, value) in map {
                if case let .utf8String(keyString) = key {
                    dict[keyString] = value.converToJsonCompatibleFormat()
                } else {
                    os_log("Non-string key encountered, which is not supported in JSON: %{PUBLIC}@", log: OSLog.default, type: .error, String(describing: key))
                }
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

func convertToCBOREncodableFormat(input: Any) -> CBOR? { // negative int?
    switch input {
    case let array as [Any]:
        return .array(array.compactMap { convertToCBOREncodableFormat(input: $0) })

    case let dict as [String: Any]:
           var map = [CBOR: CBOR]() // preserve order needed?
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
    
    case let bool as Bool:
        return .boolean(bool)
        
    case let unsignedInt as UInt64:
        return .unsignedInt(unsignedInt)

//    case let signedInt as Int:
//        return .negativeInt(UInt64(truncating: signedInt as NSNumber))
        
    case let double as Double:
        return .double(double)

    case is NSNull:
        return .null

    default:
        os_log("Unhandled or non-encodable JSON type encountered: %{PUBLIC}@", log: OSLog.default, type: .error, String(describing: input))
        return nil
    }
}

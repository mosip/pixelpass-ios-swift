import Foundation
import SwiftCBOR
import OSLog

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
            do {
                let decodedCBORIn = try CBOR.decode(data)
                
                if(decodedCBORIn==nil){
                    return String(decoding: data, as: UTF8.self)
                }
                return decodedCBORIn!.converToJsonCompatibleFormat()
            } catch {
                return String(decoding: data, as: UTF8.self)
            }
        case .boolean(let bool):
            return bool
        case .double(let double):
            return double
        case .unsignedInt(let unsignedInt):
            return unsignedInt
        case .null:
            return NSNull()
        case .tagged(_, let taggedValue):
            return taggedValue.converToJsonCompatibleFormat()
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

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
        case .map(let dict):
            var result = [String: Any]()
            for (key, value) in dict {
                let keyString : String = "\(key.converToJsonCompatibleFormat())"
                result[keyString] = value.converToJsonCompatibleFormat()
                
            }
            return result
        case .utf8String(let string):
            return string
        case .byteString(let data):
            do {
                let decodedCBORIn = try CBOR.decode(data)
                if(decodedCBORIn == nil){
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
        case .undefined:
            return NSNull()
            // Major type 1, value = -1 - (encoded unsigned integer)
        case .negativeInt(let negativeInt):
            return -1 - Int64(negativeInt)
        case .tagged(_, let taggedValue):
            return taggedValue.converToJsonCompatibleFormat()
        //simple type values assigned - https://datatracker.ietf.org/doc/html/rfc7049#section-2.3
        case .simple(let simpleValue):
            switch simpleValue {
            case 20:
                return false
            case 21:
                return true
            case 22:
                return NSNull()
            case 23: // undefined in CBOR
                return NSNull()
            default:
                return Int(simpleValue)
            }
        case .date(let date):
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: date)
        case let .float(floatValue):
            return floatValue
        case let .half(half):
            return Float(half)
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

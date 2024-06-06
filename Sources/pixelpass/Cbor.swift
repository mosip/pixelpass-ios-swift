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
    func converToJsonCompatibleFormat() -> Any {
        switch self {
        case .array(let array):
            return array.map {
                $0.converToJsonCompatibleFormat()
            }
        case .map(let map):
            var dict = [String: Any]()
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

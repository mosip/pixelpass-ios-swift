import Foundation

enum decodeByteArrayError: Error{
    case UnknownBinaryFileTypeException
    case customError(description: String)
}

enum decodeError: Error {
    case customError(description: String)
}

enum QRDataOverflowException: Error {
    case customError(description: String)
}

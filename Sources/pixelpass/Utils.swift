import Foundation

public func clearTemporaryDirectory() {
    let fileManager = FileManager.default
    let tempDirectory = fileManager.temporaryDirectory

    do {
        let tempFiles = try fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
        for file in tempFiles {
            try fileManager.removeItem(at: file)
        }
    } catch {
        print("Error clearing temporary directory: \(error)")
    }
}


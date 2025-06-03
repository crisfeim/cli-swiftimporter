// © 2025  Cristian Felipe Patiño Rojas. Created on 3/6/25.


import Foundation

extension FileManager: FileHandler {
    func getFile(_ url: URL) throws -> File? {
        var isDirectory: ObjCBool = false
        let fileExists = fileExists(atPath: url.path, isDirectory: &isDirectory)
        guard fileExists else { return nil }
        guard !isDirectory.boolValue else { return .directory }
        
        let content = try String(contentsOfFile: url.path, encoding: .utf8)
        let parentDir = url.deletingLastPathComponent()
        return .file(File.Data(url: url, content: content, parentDir: parentDir))
    }
    
    func getFileURLsOnDirectory(_ directoryURL: URL) throws -> [URL] {
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
        
        guard let enumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            throw NSError(domain: "Unable to read contents of directory", code: 0)
        }
        
    
        var files: [URL] = []
        
        for case let fileURL as URL in enumerator {
            files.append(fileURL)
        }
        
        return files
    }
}

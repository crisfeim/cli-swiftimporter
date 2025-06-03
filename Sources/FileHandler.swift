// © 2025  Cristian Felipe Patiño Rojas. Created on 3/6/25.

import Foundation

enum File {
    case directory
    case file(Data)
    
    struct Data {
        let url: URL
        let content: String
        let parentDir: URL
    }
}

protocol FileHandler {
    func getFile(_ url: URL) throws -> File?
    func getFileURLsOnDirectory(_ directoryURL: URL) throws -> [URL]
}

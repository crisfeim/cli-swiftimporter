// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation

@main
struct SwiftImportCLI: ParsableCommand {
    @Option(name: .shortAndLong, help: "Input entry point swift file") var input: String
    @Option(name: .shortAndLong, help: "The extension of the file") var ext: String = "swift"
    mutating func run() throws {
        let importer = FileImporter(keyword: "import", extension: ext)
        let fileURL = URL(fileURLWithPath: input)
        print(try importer.scanImports(ofFile: fileURL))
    }
}

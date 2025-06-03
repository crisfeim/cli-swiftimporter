// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation

@main
struct CLI: ParsableCommand {
    @Option(name: .shortAndLong, help: "Input entry point swift file") var input: String
    @Option(name: .shortAndLong, help: "The extension of the file") var ext: String = "swift"
    mutating func run() throws {
       print(try execute())
    }
    
    func execute() throws -> String {
        return try FileImporter(keyword: "import", ext: ext).makeExecutable(from: input)
    }
}

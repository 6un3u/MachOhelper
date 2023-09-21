import ArgumentParser
import Foundation

public struct MachOhelper: ParsableCommand {
    
    static public let configuration: CommandConfiguration = CommandConfiguration(
        commandName: "MachOhelper",
        abstract: "Get the hash value of the section in Segment Command of MachO file",
        discussion: "",
        version: "1.1.0"
    )

    @Argument(help: "MachO File path")
    var filePath: String
    
    @Option(name: [.customLong("seg")], help: "Segment name")
    var segment: String = SEG_TEXT

    @Option(name: [.customLong("sec")], help: "Section name")
    var section: String = SECT_TEXT
    
    public func run() throws {
        print(filePath)
        
        if let hashValue = Parser(filePath: filePath).getHashofSection(segmentName: segment, sectionName: section) {
            print(hashValue)
        } else {
            print("Can't get hash value of the section")
        }
    }
    
    public init() {
        
    }
}

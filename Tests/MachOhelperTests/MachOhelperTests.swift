import XCTest
@testable import MachOhelper

final class MachOhelperTests: XCTestCase {
    func testExample() throws {
        
//        Parser().findSection(segmentName: SEG_TEXT, sectionName: SECT_TEXT)
//        Parser().findSection(segmentName: SEG_TEXT, sectionName: "aaa")

        Log.info(Parser(filePath: "/Users/ny.kim91/tool/getHash/test1").getHashofSection(segmentName: SEG_TEXT, sectionName: SECT_TEXT))

    }
}

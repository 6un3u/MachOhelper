//
//  Parser.swift
//  
//
//  Created by 능영 김 on 2023/09/02.
//

import Foundation
import CommonCrypto
import CryptoKit
import MachO

internal struct SectionInfo {
    var section: UnsafePointer<section_64>
    var offset: UInt
}

internal struct SegmentInfo {
    var segment: UnsafePointer<segment_command_64>
    var addr: UInt64
}


internal class Parser {
    private var base: UnsafePointer<mach_header>?
    private var fileData: Data
    
    init(filePath: String) {
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            self.fileData = data
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
        
        let headerPointer = fileData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> UnsafePointer<mach_header> in
            return ptr.baseAddress!.assumingMemoryBound(to: mach_header.self)
        }
        Log.info("BaseAddr: \(headerPointer)")
        
        let magicNumber = headerPointer.pointee.magic
        Log.info("MagicNumber: \(String(magicNumber, radix: 16))")
        
        if magicNumber != MH_MAGIC_64 && magicNumber != MH_CIGAM_64 {
            print("Not machO File")
            exit(1)
        }
        
        self.base = headerPointer
    }
    
    /// Segment, section 이름을 받아와 해당 섹션을 찾는 함수
    /// - Parameters:
    ///   - segmentName: segement
    ///   - sectionName: section
    /// - Returns: section64 구조체와 해당 섹션 주소
    func findSection(segmentName: String, sectionName: String) -> SectionInfo? {
        guard let headerPointer = base else {
            return nil
        }
        
        // set first Segment
        var currentSegment = UnsafeMutableRawPointer(mutating: headerPointer).advanced(by: MemoryLayout<mach_header_64>.size)
            .bindMemory(to: segment_command_64.self, capacity: 1)
        
        // loop for segments
        for _ in 0..<headerPointer.pointee.ncmds {
            if currentSegment.pointee.cmd == LC_SEGMENT_64 {

                guard let curSegName = withUnsafePointer(to: currentSegment.pointee.segname, {ptr in
                    tupleCCharToStr(ptr)
                }) else {
                    Log.error("Segment Name Error")
                    return nil
                }
                let numOfSection = Int(currentSegment.pointee.nsects)
                
                Log.info("current segment: \(curSegName), have \(numOfSection) sects")
                
                // __PAGEZERO를 위한 예외처리
                // segment의 section 개수가 0일 경우 다음 segment로 넘어간다
                if numOfSection == 0 {
                    currentSegment = UnsafeMutableRawPointer(currentSegment).advanced(by: Int(currentSegment.pointee.cmdsize))
                        .bindMemory(to: segment_command_64.self, capacity: 1)
                    continue
                }
                
                // set first Section
                var currentSection = UnsafeMutableRawPointer(mutating: currentSegment).advanced(by: MemoryLayout<segment_command_64>.size)
                    .bindMemory(to: section_64.self, capacity: numOfSection)

                if curSegName == segmentName {
                    // loop for sections
                    for sectionID in 0..<numOfSection {
                        guard let curSecName = withUnsafePointer(to: currentSection.pointee.sectname, {ptr in
                            tupleCCharToStr(ptr)
                        }) else {
                            Log.error("Section Name Error")
                            return nil
                        }
                        print("\(sectionID) section: \(curSegName),\(curSecName)")
                        
                        if curSecName == sectionName,
                            let sectionOffset = getOffsetFromBase(UInt(currentSection.pointee.offset)) {
                            Log.info("✅ Find Section")
                            return SectionInfo(section: currentSection, offset: sectionOffset)
                        }
                        currentSection = currentSection.successor()
                    }
                }
                currentSegment = UnsafeMutableRawPointer(currentSegment).advanced(by: Int(currentSegment.pointee.cmdsize)).bindMemory(to: segment_command_64.self, capacity: 1)
            }
        }
        return nil
    }
    
    /// 섹션의 해시 값 추출 함수
    /// - Returns: sha256 해시값
    func getHashofSection(segmentName: String, sectionName: String) -> String? {
        guard let sectionInfo = findSection(segmentName: segmentName, sectionName: sectionName) else {
            print("Can't Find section")
            return nil
        }
        
        guard let sectionOffset = UnsafePointer<Any>(bitPattern: sectionInfo.offset) else {
            return nil
        }
        
        let secData = Data(bytes: sectionOffset, count: Int(sectionInfo.section.pointee.size))
        return SHA256.hash(data: secData).compactMap{String(format: "%02hhx", $0)}.joined()
    }
    
    /// offset에 base를 더한 값 리턴
    /// - Parameter offset: 오프셋
    /// - Returns: 오프셋에 baseAddr 주소를 더한 값
    private func getOffsetFromBase(_ offset: UInt) -> UInt? {
        guard let base = self.base else {
            return nil
        }
        return UInt(bitPattern: base) + offset
    }
}

extension Parser {
    
    func tupleCCharToStr(_ tupleAddr: UnsafeRawPointer) -> String? {
        return tupleAddr.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: tupleAddr)) { ptr in
            return String(cString: ptr)
        }
    }
}

extension Data {
    fileprivate func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

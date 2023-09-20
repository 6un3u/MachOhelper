//
//  LogCustom.swift
//  
//
//  Created by 능영 김 on 2023/09/02.
//
import OSLog

extension OSLog {
    private static var subsystem = "com.machOparser"

    static let info = OSLog(subsystem: subsystem, category: "Info")
    static let debug = OSLog(subsystem: subsystem, category: "Debug")
    static let error = OSLog(subsystem: subsystem, category: "Error")
}

class Log {
    enum Level {
        case info
        case debug
        case error
        case custom(category: String)
        
        fileprivate var osLogCategory: OSLog {
            switch self {
            case .info:
                return OSLog.info
            case .debug:
                return OSLog.debug
            case .error:
                return OSLog.error
            case .custom:
                return OSLog.debug
            }
        }
        
        fileprivate var osLogType: OSLogType {
            switch self {
            case .info:
                return .info
            case .debug:
                return .debug
            case .error:
                return .error
            case .custom:
                return .debug
            }
        }
    }
    
    
    static private func log(_ message: Any, level: Level) {
        os_log("%{public}@", log: level.osLogCategory, type: level.osLogType, "\(message)")
    }
}

extension Log {
    static func info(_ message: Any){
        log(message, level: .info)
    }
    
    static func debug(_ message: Any){
        log(message, level: .debug)
    }
    
    static func error(_ message: Any){
        log(message, level: .error)
    }
    
    static func custom(_ message: Any, category: String){
        log(message, level: .custom(category: category))
    }
}

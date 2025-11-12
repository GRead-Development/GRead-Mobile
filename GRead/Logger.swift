import Foundation

// Debug logging utility
enum Logger {
    #if DEBUG
    static let debugEnabled = true
    #else
    static let debugEnabled = false
    #endif

    static func debug(_ message: String) {
        #if DEBUG
        print("🔍 DEBUG: \(message)")
        #endif
    }

    static func info(_ message: String) {
        #if DEBUG
        print("ℹ️ INFO: \(message)")
        #endif
    }

    static func warning(_ message: String) {
        #if DEBUG
        print("⚠️ WARNING: \(message)")
        #else
        print("⚠️ WARNING: \(message)")
        #endif
    }

    static func error(_ message: String) {
        print("❌ ERROR: \(message)")
    }
}

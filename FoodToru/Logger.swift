//
//  Logger.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import Foundation

enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    
    var emoji: String {
        switch self {
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

class Logger {
    static let shared = Logger()
    
    private init() {}
    
    // MARK: - Public Logging Methods
    
    func debug(_ message: String, context: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log(level: .debug, message: message, context: context, file: file, function: function, line: line)
        #endif
    }
    
    func info(_ message: String, context: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log(level: .info, message: message, context: context, file: file, function: function, line: line)
        #endif
    }
    
    func warning(_ message: String, context: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log(level: .warning, message: message, context: context, file: file, function: function, line: line)
        #endif
    }
    
    func logError(_ message: String, context: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        // Error logs are always shown, even in production
        log(level: .error, message: message, context: context, file: file, function: function, line: line)
    }
    
    // MARK: - API-Specific Logging (No sensitive data)
    
    func apiRequest(url: String, method: String, context: String = "") {
        #if DEBUG
        debug("API Request: \(method) \(url)", context: context)
        #endif
    }
    
    func apiResponse(statusCode: Int, dataSize: Int, context: String = "") {
        #if DEBUG
        debug("API Response: \(statusCode) (\(dataSize) bytes)", context: context)
        #endif
    }
    
    func apiError(_ error: String, statusCode: Int? = nil, context: String = "") {
        let message = statusCode != nil ? "API Error (\(statusCode!)): \(error)" : "API Error: \(error)"
        logError(message, context: context)
    }
    
    // MARK: - Core Data Logging
    
    func coreDataError(_ error: String, context: String = "") {
        logError("Core Data Error: \(error)", context: context)
    }
    
    func coreDataSuccess(_ operation: String, context: String = "") {
        #if DEBUG
        debug("Core Data Success: \(operation)", context: context)
        #endif
    }
    
    // MARK: - Security-Safe Logging
    
    func keychainOperation(_ operation: String, success: Bool, context: String = "") {
        #if DEBUG
        let status = success ? "Success" : "Failed"
        debug("Keychain \(operation): \(status)", context: context)
        #endif
    }
    
    func apiKeyStatus(_ status: String, context: String = "") {
        #if DEBUG
        debug("API Key Status: \(status)", context: context)
        #endif
    }
    
    // MARK: - Private Methods
    
    private func log(level: LogLevel, message: String, context: String, file: String, function: String, line: Int) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let contextString = context.isEmpty ? "" : "[\(context)] "
        let location = "\(fileName):\(function):\(line)"
        
        let logMessage = "\(level.emoji) \(level.rawValue) \(contextString)\(message) - \(location)"
        print(logMessage)
    }
}

// MARK: - Convenience Extensions

extension Logger {
    func mealAnalysis(_ mealName: String, calories: Int, context: String = "") {
        #if DEBUG
        debug("Meal Analysis: \(mealName) (\(calories) cal)", context: context)
        #endif
    }
    
    func imageProcessing(_ size: Int, context: String = "") {
        #if DEBUG
        debug("Image Processing: \(size) bytes", context: context)
        #endif
    }
    
    func userAction(_ action: String, context: String = "") {
        #if DEBUG
        debug("User Action: \(action)", context: context)
        #endif
    }
}

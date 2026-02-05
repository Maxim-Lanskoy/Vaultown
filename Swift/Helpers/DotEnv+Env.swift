//
//  DotEnv+Env.swift
//  Vaultown
//
//  Universal environment variable helper with dotenv support
//
//  Created by Maxim Lanskoy on 29.01.2026.
//

import Foundation
import SwiftDotenv

// MARK: - Universal Environment Variable Helper.
public struct EnvError: Error, CustomStringConvertible {
    public let message: String
    public var description: String { message }
}

public final class Env {
    public static func get(_ key: String) throws -> String {
        if let value = ProcessInfo.processInfo.environment[key] ?? Dotenv[key]?.stringValue {
            return value
        } else {
            throw EnvError(message: "Environment variable \(key) not set.")
        }
    }

    public static func get(_ key: String, default defaultValue: String) throws -> String {
        if let value = ProcessInfo.processInfo.environment[key] ?? Dotenv[key]?.stringValue {
            return value
        } else {
            return defaultValue
        }
    }
}

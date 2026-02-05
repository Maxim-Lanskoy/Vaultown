//
//  entrypoint.swift
//  Vaultown
//
//  Application entry point with logging setup
//
//  Created by Maxim Lanskoy on 29.01.2026.
//

import Hummingbird
import Logging
import NIOCore
import NIOPosix

// MARK: - Setting up Hummingbird Application.
@main
enum Entrypoint {
    static func main() async throws {
        // Setup logging
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .info
            return handler
        }

        let logger = Logger(label: "Vaultown")

        do {
            try await configure(logger: logger)
        } catch {
            logger.error("Failed to start application: \(error)")
            throw error
        }
    }
}

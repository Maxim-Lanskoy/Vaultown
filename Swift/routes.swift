//
//  routes.swift
//  Vaultown
//
//  RouterStore actor for Telegram controller routing
//
//  Created by Maxim Lanskoy on 29.01.2026.
//

import Fluent
@preconcurrency import Lingo
import SwiftTelegramBot

// MARK: - Setting up Telegram Routes.
actor RouterStore {
    private var backStore: [String: Router] = [:]

    func set(_ router: Router, forKey key: String) {
        backStore[key] = router
    }

    func get(_ key: String) -> Router? {
        backStore[key]
    }

    func process(key: String, update: TGUpdate, properties: [String: Int64], db: any Database, lingo: Lingo) async throws {
        // Try to get the router for the key, fallback to "vault" if not found
        var router = backStore[key]
        var needsRouterFix = false
        if router == nil {
            print("[RouterStore] Router '\(key)' not found, falling back to 'vault'")
            router = backStore["vault"]
            needsRouterFix = true
        }
        guard let router = router else {
            print("[RouterStore] ERROR: No router found for '\(key)' and no fallback available")
            return
        }
        // Rehydrate Users from IDs inside actor to avoid passing non-Sendable models across actor boundary
        var hydrated: [String: User] = [:]
        for (k, v) in properties {
            let user = try await sessionCache.getOrFetch(tgId: v, db: db)
            // Fix stale routerName if we fell back
            if needsRouterFix {
                user.routerName = "vault"
                try await user.saveAndCache(in: db)
                print("[RouterStore] Fixed user \(v) routerName from '\(key)' to 'vault'")
            }
            hydrated[k] = user
        }
        try await router.process(update: update, properties: hydrated, db: db, lingo: lingo)
    }
}

// MARK: - Concurrency Safety Fixes.
// Allow passing Router instances across actors safely
extension Router: @unchecked Sendable {}

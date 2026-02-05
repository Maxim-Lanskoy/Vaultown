//
//  Lingo+Locales.swift
//  Vaultown
//
//  Lingo extensions for SupportedLocale enum integration
//
//  Created by Maxim Lanskoy on 29.01.2026.
//

import Lingo

extension Lingo {
    public func localize(_ key: LocalizationKey, locale: SupportedLocale, interpolations: [String: Any]? = nil) -> String {
        self.localize(key, locale: locale.rawValue, interpolations: interpolations)
    }
}

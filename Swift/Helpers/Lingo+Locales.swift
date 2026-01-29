//
//  Lingo+Locales.swift.swift
//  Vaultown
//
//  Created by Maxim Lanskoy on 27.12.2025.
//

import Lingo

extension Lingo {
    public func localize(_ key: LocalizationKey, locale: SupportedLocale, interpolations: [String: Any]? = nil) -> String {
        self.localize(key, locale: locale.rawValue, interpolations: interpolations)
    }
}

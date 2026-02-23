//
//  LocalizationManager.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import Foundation

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String = "system"
    
    private init() {
        currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system"
    }
    
    func setLanguage(_ language: String) {
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: "selectedLanguage")
    }
    
    func localizedString(for key: String) -> String {
        let bundle: Bundle
        
        if currentLanguage == "system" {
            // Get the system's preferred language
            let systemLanguage = getSystemPreferredLanguage()
            bundle = getBundleForLanguage(systemLanguage)
        } else {
            guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
                  let languageBundle = Bundle(path: path) else {
                bundle = Bundle.main
                return NSLocalizedString(key, comment: "")
            }
            bundle = languageBundle
        }
        
        let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")
        
        // If the localized string is the same as the key, it means the key wasn't found
        // Try to find it in English as fallback
        if localizedString == key {
            // Try English fallback
            if let englishPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let englishBundle = Bundle(path: englishPath) {
                let englishString = NSLocalizedString(key, bundle: englishBundle, comment: "")
                if englishString != key {
                    return englishString
                }
            }
            
            // If still not found, try Chinese as fallback
            if let chinesePath = Bundle.main.path(forResource: "zh-Hans", ofType: "lproj"),
               let chineseBundle = Bundle(path: chinesePath) {
                let chineseString = NSLocalizedString(key, bundle: chineseBundle, comment: "")
                if chineseString != key {
                    return chineseString
                }
            }
            
            print("Warning: Localization key '\(key)' not found for language '\(currentLanguage)'")
        }
        
        return localizedString
    }
    
    private func getSystemPreferredLanguage() -> String {
        // Get the system's preferred languages
        let preferredLanguages = Locale.preferredLanguages
        
        // Check if Chinese is preferred
        for language in preferredLanguages {
            if language.hasPrefix("zh") {
                return "zh-Hans"
            }
        }
        
        // Check if English is preferred
        for language in preferredLanguages {
            if language.hasPrefix("en") {
                return "en"
            }
        }
        
        // Default to English if no supported language is found
        return "en"
    }
    
    private func getBundleForLanguage(_ language: String) -> Bundle {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let languageBundle = Bundle(path: path) else {
            return Bundle.main
        }
        return languageBundle
    }
}

// MARK: - String Extension for Localization
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
}

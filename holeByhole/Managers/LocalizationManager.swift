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
            bundle = Bundle.main
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
        if localizedString == key {
            print("Warning: Localization key '\(key)' not found for language '\(currentLanguage)'")
        }
        
        return localizedString
    }
}

// MARK: - String Extension for Localization
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
}

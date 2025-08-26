//
//  TranslationModel.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 17.08.25.
//

import Foundation

// MARK: - Core Translation Models
struct TranslationModel {
    enum Language: String, CaseIterable {
        case english = "en"
        case azerbaijani = "az"
        case russian = "ru"
        case german = "de"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .azerbaijani: return "Azerbaijani"
            case .russian: return "Russian"
            case .german: return "German"
            }
        }
        
        var flag: String {
            switch self {
            case .english: return "🇬🇧"
            case .azerbaijani: return "🇦🇿"
            case .russian: return "🇷🇺"
            case .german: return "🇩🇪"
            }
        }
    }
    
    struct TranslationResult {
        let originalText: String
        let translatedText: String
        let sourceLanguage: Language
        let targetLanguage: Language
        let confidence: Float
        let timestamp: Date
    }
}

// MARK: - Dictionary Models
struct TranslationDictionary: Codable {
    let metadata: TranslationMetadata
    let translations: [String: [String: String]]
    let phrases: [String: [String: String]]
}

struct TranslationMetadata: Codable {
    let version: String
    let languages: [String]
    let lastUpdated: String
    let totalEntries: Int
}

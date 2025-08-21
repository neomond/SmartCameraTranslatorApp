//
//  JSONTranslationService.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 17.08.25.
//

import Foundation
import NaturalLanguage
import Combine

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

// MARK: - Translation Dictionary Models
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

// MARK: - Translation Cache
@MainActor
class TranslationCache {
    private var cache: [String: TranslationModel.TranslationResult] = [:]
    
    func set(_ result: TranslationModel.TranslationResult, for key: String) {
        cache[key] = result
    }
    
    func get(for key: String) -> TranslationModel.TranslationResult? {
        cache[key]
    }
    
    func clear() {
        cache.removeAll()
    }
}

// MARK: - Main Translation Service
@MainActor
class JSONTranslationService: ObservableObject {
    @Published var sourceLanguage: TranslationModel.Language = .english
    @Published var targetLanguage: TranslationModel.Language = .azerbaijani
    @Published var isTranslating = false
    @Published var translationHistory: [TranslationModel.TranslationResult] = []
    @Published var error: String?
    @Published var supportsTranslation = true
    @Published var dictionaryStatus: DictionaryStatus = .loading
    
    private var cache = TranslationCache()
    private var translationDictionary: TranslationDictionary?
    
    enum DictionaryStatus {
        case loading
        case ready
        case error(String)
        
        var displayText: String {
            switch self {
            case .loading: return "Loading dictionary..."
            case .ready: return "Dictionary ready"
            case .error(let message): return "Error: \(message)"
            }
        }
    }
    
    init() {
        loadTranslationDictionary()
    }
    
    private func loadTranslationDictionary() {
        guard let url = Bundle.main.url(forResource: "translations", withExtension: "json") else {
            dictionaryStatus = .error("translations.json not found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            translationDictionary = try JSONDecoder().decode(TranslationDictionary.self, from: data)
            dictionaryStatus = .ready
            print("📚 Dictionary loaded: \(translationDictionary?.metadata.totalEntries ?? 0) entries")
        } catch {
            dictionaryStatus = .error("Failed to parse translations.json: \(error.localizedDescription)")
            print("❌ Failed to load translation dictionary: \(error)")
        }
    }
    
    func translate(_ text: String, from source: TranslationModel.Language? = nil, to target: TranslationModel.Language? = nil) async -> String {
        let sourceL = source ?? detectLanguage(for: text)
        let targetL = target ?? targetLanguage
        
        // Check cache first
        let cacheKey = "\(text)_\(sourceL.rawValue)_\(targetL.rawValue)"
        if let cached = cache.get(for: cacheKey) {
            return cached.translatedText
        }
        
        // Update languages if needed
        if sourceL != sourceLanguage || targetL != targetLanguage {
            sourceLanguage = sourceL
            targetLanguage = targetL
        }
        
        isTranslating = true
        error = nil
        
        // Add realistic delay for better UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let translatedText = performTranslation(text, from: sourceL, to: targetL)
        
        // Save to history and cache
        let result = TranslationModel.TranslationResult(
            originalText: text,
            translatedText: translatedText,
            sourceLanguage: sourceL,
            targetLanguage: targetL,
            confidence: getTranslationConfidence(for: translatedText, original: text),
            timestamp: Date()
        )
        
        translationHistory.insert(result, at: 0)
        if translationHistory.count > 50 {
            translationHistory.removeLast()
        }
        
        cache.set(result, for: cacheKey)
        HapticService.shared.notification(type: .success)
        
        isTranslating = false
        return translatedText
    }
    
    private func performTranslation(_ text: String, from source: TranslationModel.Language, to target: TranslationModel.Language) -> String {
        guard let dictionary = translationDictionary else {
            return "Dictionary not loaded"
        }
        
        // Try exact phrase match first
        let phraseKey = text.lowercased().replacingOccurrences(of: " ", with: "_")
        if let phraseTranslations = dictionary.phrases[phraseKey],
           let translation = phraseTranslations[target.rawValue] {
            return translation
        }
        
        // Try exact word match
        let wordKey = text.lowercased()
        if let wordTranslations = dictionary.translations[wordKey],
           let translation = wordTranslations[target.rawValue] {
            return translation
        }
        
        // Try case-insensitive search
        for (key, translations) in dictionary.translations {
            if key.lowercased() == text.lowercased(),
               let translation = translations[target.rawValue] {
                return translation
            }
        }
        
        // Try word-by-word translation
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        if words.count > 1 {
            var translatedWords: [String] = []
            
            for word in words {
                let cleanWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
                
                if let wordTranslations = dictionary.translations[cleanWord],
                   let translation = wordTranslations[target.rawValue] {
                    translatedWords.append(translation)
                } else {
                    // Keep original word if no translation found
                    translatedWords.append(word)
                }
            }
            
            let result = translatedWords.joined(separator: " ")
            return result != text ? result : "[\(text)]"
        }
        
        // No translation found
        return "[\(text)]"
    }
    
    private func getTranslationConfidence(for translation: String, original: String) -> Float {
        if translation.hasPrefix("[") && translation.hasSuffix("]") {
            return 0.0 // No translation found
        } else if translation.contains(original) {
            return 0.5 // Partial translation
        } else {
            return 0.9 // Full translation
        }
    }
    
    // Auto-detect language using NaturalLanguage framework
    func detectLanguage(for text: String) -> TranslationModel.Language {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let languageCode = recognizer.dominantLanguage?.rawValue else {
            return .english
        }
        
        switch languageCode {
        case "en": return .english
        case "az": return .azerbaijani
        case "ru": return .russian
        case "de": return .german
        default: return .english
        }
    }
    
    // Check if translation exists in dictionary
    func hasTranslation(for text: String, from source: TranslationModel.Language, to target: TranslationModel.Language) -> Bool {
        guard let dictionary = translationDictionary else { return false }
        
        let wordKey = text.lowercased()
        let phraseKey = text.lowercased().replacingOccurrences(of: " ", with: "_")
        
        // Check phrases first
        if let phraseTranslations = dictionary.phrases[phraseKey],
           phraseTranslations[target.rawValue] != nil {
            return true
        }
        
        // Check individual words
        if let wordTranslations = dictionary.translations[wordKey],
           wordTranslations[target.rawValue] != nil {
            return true
        }
        
        return false
    }
    
    // Get dictionary statistics
    func getDictionaryStats() -> (words: Int, phrases: Int, languages: [String]) {
        guard let dictionary = translationDictionary else {
            return (0, 0, [])
        }
        
        return (
            words: dictionary.translations.count,
            phrases: dictionary.phrases.count,
            languages: dictionary.metadata.languages
        )
    }
    
    // Search dictionary for similar words
    func searchSimilarWords(for text: String, in language: TranslationModel.Language) -> [String] {
        guard let dictionary = translationDictionary else { return [] }
        
        let searchTerm = text.lowercased()
        var results: [String] = []
        
        // Search in translations
        for (key, translations) in dictionary.translations {
            if key.contains(searchTerm) || searchTerm.contains(key) {
                if let translation = translations[language.rawValue] {
                    results.append("\(key) → \(translation)")
                }
            }
        }
        
        // Search in phrases
        for (key, translations) in dictionary.phrases {
            let readableKey = key.replacingOccurrences(of: "_", with: " ")
            if readableKey.contains(searchTerm) || searchTerm.contains(readableKey) {
                if let translation = translations[language.rawValue] {
                    results.append("\(readableKey) → \(translation)")
                }
            }
        }
        
        return Array(results.prefix(10)) // Limit to 10 results
    }
    
    func clearHistory() {
        translationHistory.removeAll()
        cache.clear()
    }
    
    func switchLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
    }
    
    // Reload dictionary (useful for updates)
    func reloadDictionary() {
        dictionaryStatus = .loading
        loadTranslationDictionary()
    }
}

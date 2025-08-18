//
//  TranslationService.swift
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
    case turkish = "tr"
    case spanish = "es"
    case french = "fr"
    
    var displayName: String {
      switch self {
      case .english: return "English"
      case .azerbaijani: return "Azerbaijani"
      case .russian: return "Russian"
      case .turkish: return "Turkish"
      case .spanish: return "Spanish"
      case .french: return "French"
      }
    }
    
    var flag: String {
      switch self {
      case .english: return "🇬🇧"
      case .azerbaijani: return "🇦🇿"
      case .russian: return "🇷🇺"
      case .turkish: return "🇹🇷"
      case .spanish: return "🇪🇸"
      case .french: return "🇫🇷"
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

// Separate cache class to avoid struct mutation issues
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


@MainActor
class TranslationService: ObservableObject {
  @Published var sourceLanguage: TranslationModel.Language = .english
  @Published var targetLanguage: TranslationModel.Language = .azerbaijani
  @Published var isTranslating = false
  @Published var translationHistory: [TranslationModel.TranslationResult] = []
  
  private var cache = TranslationCache()
  
  // Fixed dictionary structure - properly nested
  private let translationData: [String: [String: [String: String]]] = [
    "en": [
      "az": [
        // Common words
        "Hello": "Salam",
        "Welcome": "Xoş gəlmisiniz",
        "Settings": "Tənzimləmələr",
        "Camera": "Kamera",
        "Text": "Mətn",
        "Done": "Hazır",
        "Cancel": "Ləğv et",
        "Save": "Saxla",
        "Delete": "Sil",
        "Edit": "Redaktə",
        "Share": "Paylaş",
        "Open": "Aç",
        "Close": "Bağla",
        "Search": "Axtar",
        "Filter": "Filtr",
        "Sort": "Sırala",
        "Copy": "Kopyala",
        "Paste": "Yapışdır",
        "Cut": "Kəs",
        // Tech terms
        "Computer": "Kompüter",
        "Screen": "Ekran",
        "Keyboard": "Klaviatura",
        "Mouse": "Siçan",
        "File": "Fayl",
        "Folder": "Qovluq",
        "Download": "Yüklə",
        "Upload": "Yüklə",
        "Internet": "İnternet",
        "Network": "Şəbəkə",
        "Password": "Parol",
        "Username": "İstifadəçi adı",
        "Login": "Giriş",
        "Logout": "Çıxış",
        "Register": "Qeydiyyat",
        // Common phrases
        "Good morning": "Sabahınız xeyir",
        "Good evening": "Axşamınız xeyir",
        "Thank you": "Təşəkkür edirəm",
        "Please": "Zəhmət olmasa",
        "Yes": "Bəli",
        "No": "Xeyr",
        // Numbers
        "One": "Bir",
        "Two": "İki",
        "Three": "Üç",
        "Four": "Dörd",
        "Five": "Beş"
      ],
      "ru": [
        "Hello": "Привет",
        "Welcome": "Добро пожаловать",
        "Settings": "Настройки",
        "Camera": "Камера",
        "Text": "Текст",
        "Done": "Готово",
        "Computer": "Компьютер",
        "Screen": "Экран",
        "Yes": "Да",
        "No": "Нет"
      ],
      "tr": [
        "Hello": "Merhaba",
        "Welcome": "Hoş geldiniz",
        "Settings": "Ayarlar",
        "Camera": "Kamera",
        "Text": "Metin",
        "Done": "Tamam",
        "Computer": "Bilgisayar",
        "Yes": "Evet",
        "No": "Hayır"
      ]
    ]
  ]
  
  // Auto-detect language using NaturalLanguage framework
  func detectLanguage(for text: String) -> TranslationModel.Language {
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    
    guard let languageCode = recognizer.dominantLanguage?.rawValue else {
      return .english // default
    }
    
    switch languageCode {
    case "en": return .english
    case "az": return .azerbaijani
    case "ru": return .russian
    case "tr": return .turkish
    case "es": return .spanish
    case "fr": return .french
    default: return .english
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
    
    // Set translating state
    isTranslating = true
    
    // Small delay to show loading state (remove in production)
    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    
    // For Week 1: Use dictionary
    let translatedText = performDictionaryTranslation(text, from: sourceL, to: targetL)
    
    // Save to history and cache
    let result = TranslationModel.TranslationResult(
      originalText: text,
      translatedText: translatedText,
      sourceLanguage: sourceL,
      targetLanguage: targetL,
      confidence: 0.95,
      timestamp: Date()
    )
    
    translationHistory.insert(result, at: 0)
    if translationHistory.count > 50 {
      translationHistory.removeLast()
    }
    
    cache.set(result, for: cacheKey)
    
    // Reset translating state
    isTranslating = false
    
    return translatedText
  }
  
  private func performDictionaryTranslation(_ text: String, from source: TranslationModel.Language, to target: TranslationModel.Language) -> String {
    // Get the translation dictionary for source -> target
    guard let sourceDict = translationData[source.rawValue],
          let targetDict = sourceDict[target.rawValue] else {
      return "[\(text)]" // No translation available
    }
    
    // Try exact match
    if let translation = targetDict[text] {
      return translation
    }
    
    // Try case-insensitive match
    let lowercasedText = text.lowercased()
    if let translation = targetDict.first(where: { $0.key.lowercased() == lowercasedText })?.value {
      return translation
    }
    
    // Try word-by-word translation for phrases
    let words = text.components(separatedBy: " ")
    var translatedWords: [String] = []
    
    for word in words {
      if let translatedWord = targetDict[word] {
        translatedWords.append(translatedWord)
      } else if let translatedWord = targetDict.first(where: { $0.key.lowercased() == word.lowercased() })?.value {
        translatedWords.append(translatedWord)
      } else {
        translatedWords.append(word) // Keep original if not found
      }
    }
    
    let result = translatedWords.joined(separator: " ")
    return result != text ? result : "[\(text)]" // Brackets indicate no translation
  }
  
  func clearHistory() {
    translationHistory.removeAll()
    cache.clear()
  }
}

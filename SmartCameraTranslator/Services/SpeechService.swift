//
//  SpeechService.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 17.08.25.
//

import Foundation
import AVFoundation
import Combine

// MARK: - Speech Service
@MainActor
class SpeechService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isSpeaking = false
    @Published var isEnabled = true
    @Published var speechRate: Float = 0.5
    @Published var speechVolume: Float = 1.0
    @Published var error: String?
    
    // MARK: - Private Properties
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var preferredVoices: [String: String] = [:]
    
    static let shared = SpeechService()
    
    // MARK: - Initialization
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
        loadVoicePreferences()
        loadSettings()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
            self.error = "Audio setup failed"
        }
    }
    
    // MARK: - Voice Configuration
    private func loadVoicePreferences() {
        preferredVoices = [
            "en": "com.apple.ttsbundle.Samantha-compact",
            "az": "com.apple.ttsbundle.siri_female_en-US_compact", // Fallback
            "ru": "com.apple.ttsbundle.Milena-compact",
            "de": "com.apple.ttsbundle.Anna-compact"
        ]
    }
    
    // MARK: - Main Speech Functions
    func speak(_ text: String, language: TranslationModel.Language, isTranslation: Bool = false) {
        guard isEnabled && !text.isEmpty else { return }
        
        stopSpeaking()
        
        let cleanText = cleanTextForSpeech(text)
        guard !cleanText.isEmpty else { return }
        
        let utterance = AVSpeechUtterance(string: cleanText)
        
        if let voice = getBestVoice(for: language) {
            utterance.voice = voice
        }
        
        utterance.rate = speechRate
        utterance.volume = speechVolume
        utterance.pitchMultiplier = isTranslation ? 1.1 : 1.0
        
        currentUtterance = utterance
        HapticService.shared.impact(style: .light)
        
        synthesizer.speak(utterance)
    }
    
    func speakOriginal(_ text: String, language: TranslationModel.Language) {
        speak(text, language: language, isTranslation: false)
    }
    
    func speakTranslation(_ text: String, language: TranslationModel.Language) {
        speak(text, language: language, isTranslation: true)
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            currentUtterance = nil
            isSpeaking = false
        }
    }
    
    func pauseSpeaking() {
        if synthesizer.isSpeaking && !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    func resumeSpeaking() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
    
    // MARK: - Voice Selection
    private func getBestVoice(for language: TranslationModel.Language) -> AVSpeechSynthesisVoice? {
        let languageCode = language.rawValue
        
        // Try preferred voice first
        if let preferredVoiceId = preferredVoices[languageCode],
           let voice = AVSpeechSynthesisVoice(identifier: preferredVoiceId) {
            return voice
        }
        
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()
        
        // Try exact language match
        if let voice = availableVoices.first(where: { $0.language.hasPrefix(languageCode) }) {
            return voice
        }
        
        // Language-specific fallbacks
        switch language {
        case .azerbaijani:
            return availableVoices.first { $0.language.hasPrefix("tr") } ??
                   availableVoices.first { $0.language.hasPrefix("en") }
        case .english:
            return availableVoices.first { $0.language.hasPrefix("en") }
        case .russian:
            return availableVoices.first { $0.language.hasPrefix("ru") }
        case .german:
            return availableVoices.first { $0.language.hasPrefix("de") }
        }
    }
    
    // MARK: - Text Processing
    private func cleanTextForSpeech(_ text: String) -> String {
        var cleaned = text
        
        // Remove untranslated markers
        cleaned = cleaned.replacingOccurrences(
            of: #"\[.*?\]"#,
            with: "",
            options: .regularExpression
        )
        
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Improve pronunciation
        let pronunciationMap: [String: String] = [
            "Dr.": "Doctor",
            "Mr.": "Mister",
            "Mrs.": "Misses",
            "Ms.": "Miss",
            "Prof.": "Professor",
            "&": "and",
            "@": "at",
            "%": "percent",
            "#": "number"
        ]
        
        for (abbreviation, expansion) in pronunciationMap {
            cleaned = cleaned.replacingOccurrences(of: abbreviation, with: expansion)
        }
        
        return cleaned
    }
    
    // MARK: - Voice Information
    func getAvailableVoices(for language: TranslationModel.Language) -> [AVSpeechSynthesisVoice] {
        let languageCode = language.rawValue
        return AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.hasPrefix(languageCode)
        }
    }
    
    func getVoiceInfo(for language: TranslationModel.Language) -> (count: Int, quality: String) {
        let voices = getAvailableVoices(for: language)
        let hasHighQuality = voices.contains { $0.quality == .enhanced }
        
        return (
            count: voices.count,
            quality: hasHighQuality ? "Enhanced" : voices.isEmpty ? "Not Available" : "Standard"
        )
    }
    
    // MARK: - Settings Management
    func setSpeechRate(_ rate: Float) {
        speechRate = max(0.0, min(1.0, rate))
        UserDefaults.standard.set(speechRate, forKey: "SpeechRate")
    }
    
    func setSpeechVolume(_ volume: Float) {
        speechVolume = max(0.0, min(1.0, volume))
        UserDefaults.standard.set(speechVolume, forKey: "SpeechVolume")
    }
    
    func toggleEnabled() {
        isEnabled.toggle()
        if !isEnabled {
            stopSpeaking()
        }
        UserDefaults.standard.set(isEnabled, forKey: "SpeechEnabled")
    }
    
    private func loadSettings() {
        speechRate = UserDefaults.standard.object(forKey: "SpeechRate") as? Float ?? 0.5
        speechVolume = UserDefaults.standard.object(forKey: "SpeechVolume") as? Float ?? 1.0
        isEnabled = UserDefaults.standard.object(forKey: "SpeechEnabled") as? Bool ?? true
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechService: AVSpeechSynthesizerDelegate {
    
    // Mark delegate methods as nonisolated to match protocol requirements
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = true
            error = nil
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            currentUtterance = nil
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            currentUtterance = nil
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        // Keep isSpeaking true when paused
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        // Already handled in didStart
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // Could be used for highlighting text being spoken
    }
}

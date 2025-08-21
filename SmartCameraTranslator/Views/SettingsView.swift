//
//  SettingsView.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 17.08.25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var translationService: JSONTranslationService
    @StateObject private var speechService = SpeechService.shared
    @State private var showDictionaryInfo = false
    @State private var searchText = ""
    @State private var searchResults: [String] = []
    
    var body: some View {
        NavigationView {
            List {
                Section("Speech Settings") {
                    HStack {
                        Label("Text-to-Speech", systemImage: "speaker.2")
                        Spacer()
                        Toggle("", isOn: $speechService.isEnabled)
                    }
                    
                    if speechService.isEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Speech Rate", systemImage: "speedometer")
                                Spacer()
                                Text("\(Int(speechService.speechRate * 100))%")
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $speechService.speechRate, in: 0.1...1.0, step: 0.1)
                                .onChange(of: speechService.speechRate) { _, newValue in
                                    speechService.setSpeechRate(newValue)
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Volume", systemImage: "speaker.wave.2")
                                Spacer()
                                Text("\(Int(speechService.speechVolume * 100))%")
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $speechService.speechVolume, in: 0.1...1.0, step: 0.1)
                                .onChange(of: speechService.speechVolume) { _, newValue in
                                    speechService.setSpeechVolume(newValue)
                                }
                        }
                        
                        // Voice quality info
                        ForEach(TranslationModel.Language.allCases, id: \.self) { language in
                            let voiceInfo = speechService.getVoiceInfo(for: language)
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                                    .font(.caption)
                                Spacer()
                                Text(voiceInfo.quality)
                                    .font(.caption2)
                                    .foregroundColor(voiceInfo.quality == "Enhanced" ? .green :
                                                   voiceInfo.quality == "Standard" ? .orange : .red)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.secondary.opacity(0.1))
                                    )
                            }
                        }
                        
                        // Test speech button
                        Button(action: testSpeech) {
                            HStack {
                                Image(systemName: speechService.isSpeaking ? "speaker.wave.2.fill" : "play.circle")
                                Text(speechService.isSpeaking ? "Speaking..." : "Test Speech")
                            }
                        }
                        .disabled(speechService.isSpeaking)
                    }
                }
                
                Section("Translation Settings") {
                    // Source Language
                    Picker("From", selection: $translationService.sourceLanguage) {
                        ForEach(TranslationModel.Language.allCases, id: \.self) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                            }
                            .tag(language)
                        }
                    }
                    
                    // Swap button
                    HStack {
                        Spacer()
                        Button(action: switchLanguages) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.title3)
                        }
                        Spacer()
                    }
                    
                    // Target Language
                    Picker("To", selection: $translationService.targetLanguage) {
                        ForEach(TranslationModel.Language.allCases, id: \.self) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                            }
                            .tag(language)
                        }
                    }
                }
                
                Section("Dictionary Status") {
                    HStack {
                        Label("Status", systemImage: statusIcon)
                        Spacer()
                        Text(translationService.dictionaryStatus.displayText)
                            .foregroundColor(statusColor)
                            .font(.caption)
                    }
                    
                    if case .ready = translationService.dictionaryStatus {
                        let stats = translationService.getDictionaryStats()
                        
                        HStack {
                            Label("Words", systemImage: "textformat")
                            Spacer()
                            Text("\(stats.words)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Phrases", systemImage: "quote.bubble")
                            Spacer()
                            Text("\(stats.phrases)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Languages", systemImage: "globe")
                            Spacer()
                            Text("\(stats.languages.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: { showDictionaryInfo = true }) {
                        HStack {
                            Label("Dictionary Info", systemImage: "info.circle")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Dictionary Search") {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search dictionary...", text: $searchText)
                            .onChange(of: searchText) { _, newValue in
                                if !newValue.isEmpty {
                                    searchResults = translationService.searchSimilarWords(
                                        for: newValue,
                                        in: translationService.targetLanguage
                                    )
                                } else {
                                    searchResults = []
                                }
                            }
                    }
                    
                    if !searchResults.isEmpty {
                        ForEach(searchResults, id: \.self) { result in
                            Text(result)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if !searchText.isEmpty {
                        Text("No results found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .italic()
                    }
                }
                
                Section("Translation History") {
                    if translationService.translationHistory.isEmpty {
                        Text("No translations yet")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(translationService.translationHistory.prefix(5), id: \.timestamp) { result in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(result.sourceLanguage.flag)
                                    Text(result.originalText)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer()
                                    ConfidenceIndicator(confidence: result.confidence)
                                }
                                HStack {
                                    Text(result.targetLanguage.flag)
                                    Text(result.translatedText)
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        
                        Button("Clear History") {
                            translationService.clearHistory()
                            HapticService.shared.notification(type: .success)
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Translation Engine")
                        Spacer()
                        Text("JSON Dictionary")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Supported Languages")
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(TranslationModel.Language.allCases, id: \.self) { language in
                                Text(language.flag)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
        .sheet(isPresented: $showDictionaryInfo) {
            DictionaryInfoView(translationService: translationService)
        }
    }
    
    private var statusIcon: String {
        switch translationService.dictionaryStatus {
        case .loading: return "clock"
        case .ready: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusColor: Color {
        switch translationService.dictionaryStatus {
        case .loading: return .orange
        case .ready: return .green
        case .error: return .red
        }
    }
    
    private func switchLanguages() {
        translationService.switchLanguages()
        HapticService.shared.impact(style: .light)
    }
    
    private func testSpeech() {
        let testText = "Hello! This is a test of the text-to-speech feature."
        speechService.speakOriginal(testText, language: .english)
        HapticService.shared.impact(style: .light)
    }
}

// MARK: - Confidence Indicator
struct ConfidenceIndicator: View {
    let confidence: Float
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(fillColor(for: index))
                    .frame(width: 4, height: 4)
            }
        }
    }
    
    private func fillColor(for index: Int) -> Color {
        let threshold = Float(index + 1) * 0.33
        return confidence >= threshold ? .green : .gray.opacity(0.3)
    }
}

// MARK: - Dictionary Info View
struct DictionaryInfoView: View {
    let translationService: JSONTranslationService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Dictionary Information") {
                    let stats = translationService.getDictionaryStats()
                    
                    InfoRow(title: "Total Words", value: "\(stats.words)", icon: "textformat")
                    InfoRow(title: "Total Phrases", value: "\(stats.phrases)", icon: "quote.bubble")
                    InfoRow(title: "Languages", value: "\(stats.languages.count)", icon: "globe")
                    InfoRow(title: "Storage", value: "Local JSON", icon: "internaldrive")
                    InfoRow(title: "Offline", value: "Always Available", icon: "wifi.slash")
                }
                
                Section("Supported Languages") {
                    ForEach(TranslationModel.Language.allCases, id: \.self) { language in
                        HStack {
                            Text(language.flag)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text(language.displayName)
                                    .font(.headline)
                                Text(language.rawValue.uppercased())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Features") {
                    FeatureRow(
                        icon: "bolt.fill",
                        title: "Instant Translation",
                        description: "No network required"
                    )
                    
                    FeatureRow(
                        icon: "brain",
                        title: "Smart Matching",
                        description: "Word and phrase recognition"
                    )
                    
                    FeatureRow(
                        icon: "magnifyingglass",
                        title: "Dictionary Search",
                        description: "Find similar words"
                    )
                    
                    FeatureRow(
                        icon: "shield.fill",
                        title: "Privacy First",
                        description: "All processing on-device"
                    )
                }
                
                Section("Actions") {
                    Button(action: {
                        translationService.reloadDictionary()
                        HapticService.shared.impact(style: .medium)
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Reload Dictionary")
                        }
                    }
                }
            }
            .navigationTitle("Dictionary Info")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - Helper Views
struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView(translationService: JSONTranslationService())
}

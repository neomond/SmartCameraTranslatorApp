//
//  LanguageDownloadView.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 19.08.25.
//

import SwiftUI

struct LanguageDownloadView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var translationService = JSONTranslationService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "globe")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Language Packs")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enhanced dictionary translations are always available offline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Language Status
                List {
                    Section("Available Languages") {
                        ForEach(TranslationModel.Language.allCases, id: \.self) { language in
                            HStack {
                                Text(language.flag)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text(language.displayName)
                                        .font(.headline)
                                    Text("Dictionary Based")
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
                    
                    Section("Dictionary Status") {
                        HStack {
                            Image(systemName: statusIcon)
                                .foregroundColor(statusColor)
                            Text("Status")
                            Spacer()
                            Text(translationService.dictionaryStatus.displayText)
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        
                        if case .ready = translationService.dictionaryStatus {
                            let stats = translationService.getDictionaryStats()
                            
                            HStack {
                                Image(systemName: "textformat")
                                    .foregroundColor(.blue)
                                Text("Words")
                                Spacer()
                                Text("\(stats.words)")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "quote.bubble")
                                    .foregroundColor(.blue)
                                Text("Phrases")
                                Spacer()
                                Text("\(stats.phrases)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section("Features") {
                        LanguageFeatureRow(
                            icon: "bolt.fill",
                            title: "Instant Translation",
                            description: "No download required"
                        )
                        
                        LanguageFeatureRow(
                            icon: "wifi.slash",
                            title: "Works Offline",
                            description: "Always available"
                        )
                        
                        LanguageFeatureRow(
                            icon: "brain",
                            title: "Smart Detection",
                            description: "Auto language detection"
                        )
                        
                        LanguageFeatureRow(
                            icon: "shield.fill",
                            title: "Privacy First",
                            description: "On-device processing"
                        )
                        
                        LanguageFeatureRow(
                            icon: "arrow.clockwise",
                            title: "Auto Updates",
                            description: "Dictionary improvements"
                        )
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Language Packs")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
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
}

// Use a unique name to avoid conflicts with SettingsView
struct LanguageFeatureRow: View {
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
    LanguageDownloadView()
}

//
//  SettingsView.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 17.08.25.
//

import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) var dismiss
  @StateObject private var translationService = TranslationService()
  
  var body: some View {
    NavigationView {
      List {
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
        
        Section("History") {
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
                }
                HStack {
                  Text(result.targetLanguage.flag)
                  Text(result.translatedText)
                    .font(.caption)
                    .foregroundColor(.green)
                }
              }
            }
            
            Button("Clear History") {
              translationService.clearHistory()
            }
            .foregroundColor(.red)
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarItems(trailing: Button("Done") { dismiss() })
    }
  }
  
  private func switchLanguages() {
    let temp = translationService.sourceLanguage
    translationService.sourceLanguage = translationService.targetLanguage
    translationService.targetLanguage = temp
    HapticService.shared.impact(style: .light)
  }
}

#Preview {
  SettingsView()
}

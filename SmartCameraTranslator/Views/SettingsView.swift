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
  @State private var showLanguageInfo = false
  
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
        
        Section("Translation Engine") {
          HStack {
            Label("Engine Type", systemImage: "brain")
            Spacer()
            Text("Enhanced Dictionary")
              .foregroundColor(.blue)
          }
          
          Button(action: { showLanguageInfo = true }) {
            HStack {
              Label("Language Packs", systemImage: "globe")
              Spacer()
              Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
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
                    .lineLimit(1)
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
            Text("1.0")
              .foregroundColor(.secondary)
          }
          
          HStack {
            Text("Translation Engine")
            Spacer()
            Text("Enhanced Dictionary")
              .foregroundColor(.secondary)
          }
          
          HStack {
            Text("Supported Languages")
            Spacer()
            Text("\(TranslationModel.Language.allCases.count)")
              .foregroundColor(.secondary)
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarItems(trailing: Button("Done") { dismiss() })
    }
    .sheet(isPresented: $showLanguageInfo) {
      LanguageDownloadView()
    }
  }
  
  private func switchLanguages() {
    translationService.switchLanguages()
    HapticService.shared.impact(style: .light)
  }
}

#Preview {
  SettingsView()
}

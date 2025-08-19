//
//  LanguageDownloadView.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 19.08.25.
//

import SwiftUI

struct LanguageDownloadView: View {
  @Environment(\.dismiss) var dismiss
  @StateObject private var translationService = TranslationService()
  
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
          
          Section("Features") {
            FeatureRow(
              icon: "bolt.fill",
              title: "Instant Translation",
              description: "No download required"
            )
            
            FeatureRow(
              icon: "wifi.slash",
              title: "Works Offline",
              description: "Always available"
            )
            
            FeatureRow(
              icon: "brain",
              title: "Smart Detection",
              description: "Auto language detection"
            )
            
            FeatureRow(
              icon: "shield.fill",
              title: "Privacy First",
              description: "On-device processing"
            )
          }
        }
        
        Spacer()
      }
      .navigationTitle("Language Packs")
      .navigationBarItems(trailing: Button("Done") { dismiss() })
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
  LanguageDownloadView()
}

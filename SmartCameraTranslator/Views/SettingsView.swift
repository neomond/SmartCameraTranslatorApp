//
//  SettingsView.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 17.08.25.
//

import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) var dismiss
  
  var body: some View {
    NavigationView {
      List {
        Section("Translation") {
          HStack {
            Text("From")
            Spacer()
            Text("Auto-detect")
              .foregroundColor(.gray)
          }
          
          HStack {
            Text("To")
            Spacer()
            Text("Azerbaijani")
              .foregroundColor(.gray)
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarItems(trailing: Button("Done") { dismiss() })
    }
  }
}

#Preview {
  SettingsView()
}

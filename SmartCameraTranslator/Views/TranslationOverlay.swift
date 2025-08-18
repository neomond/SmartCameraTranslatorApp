//
//  TranslationOverlay.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 17.08.25.
//

import SwiftUI

struct TranslationOverlay: View {
  let detectedTexts: [DetectedText]
  let geometrySize: CGSize
  @State private var selectedText: DetectedText?
  @State private var showTranslation = false
  
  var body: some View {
    ZStack {
      ForEach(detectedTexts) { detection in
        let rect = detection.convertedBoundingBox(for: geometrySize)
        
        // More subtle bounding box
        RoundedRectangle(cornerRadius: 4)
          .stroke(
            selectedText?.id == detection.id ? Color.green : Color.blue.opacity(0.8),
            lineWidth: selectedText?.id == detection.id ? 3 : 2
          )
          .frame(width: rect.width, height: rect.height)
          .position(x: rect.midX, y: rect.midY)
          .animation(.easeInOut(duration: 0.2), value: selectedText?.id)
        
        // Floating translation bubble (only for selected)
        if selectedText?.id == detection.id && showTranslation {
          TranslationBubble(
            original: detection.text,
            translated: translateBasic(detection.text),
            position: CGPoint(x: rect.midX, y: rect.minY - 30)
          )
          .transition(.scale.combined(with: .opacity))
        }
      }
    }
    .onTapGesture { location in
      // Check if tap is on any text
      var tappedText: DetectedText?
      
      for detection in detectedTexts {
        let rect = detection.convertedBoundingBox(for: geometrySize)
        if rect.contains(location) {
          tappedText = detection
          break
        }
      }
      
      if tappedText != nil {
        if selectedText?.id == tappedText?.id {
          HapticService.shared.selection() // Different haptic for toggling
        } else {
          HapticService.shared.impact(style: .light) // New selection
        }
      }
      
      withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        if let tapped = tappedText {
          if selectedText?.id == tapped.id {
            showTranslation.toggle()
          } else {
            selectedText = tapped
            showTranslation = true
          }
        } else {
          selectedText = nil
          showTranslation = false
        }
      }
    }
  }
  
  private func translateBasic(_ text: String) -> String {
    let translations: [String: String] = [
      "Settings": "Tənzimləmələr",
      "Point": "Yönəlt",
      "camera": "kamera",
      "text": "mətn",
      "Done": "Hazır",
      "Translation": "Tərcümə",
      "Research": "Tədqiqat",
      "Reply": "Cavab",
      "Computer": "Kompüter",
      "screen": "ekran",
      "book": "kitab",
      "detected": "aşkarlandı"
    ]
    
    // Try exact match first
    if let exact = translations[text] {
      return exact
    }
    
    // Try case-insensitive
    if let match = translations.first(where: { $0.key.lowercased() == text.lowercased() }) {
      return match.value
    }
    
    return "Tərcümə edilir..."
  }
}

// Separate bubble component
struct TranslationBubble: View {
  let original: String
  let translated: String
  let position: CGPoint
  
  var body: some View {
    VStack(spacing: 4) {
      Text(original)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue)
        .cornerRadius(8)
      
      Text(translated)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.green)
        .cornerRadius(8)
    }
    .position(position)
  }
}

#Preview {
    // Create a container view to properly display the preview
    ZStack {
        // Background to simulate camera
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.black, .gray.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .ignoresSafeArea()
        
        // The overlay with mock data
        TranslationOverlay(
            detectedTexts: [
                DetectedText(
                    text: "Hello",
                    boundingBox: CGRect(x: 0.3, y: 0.6, width: 0.2, height: 0.05),
                    confidence: 0.95
                ),
                DetectedText(
                    text: "Settings",
                    boundingBox: CGRect(x: 0.1, y: 0.4, width: 0.3, height: 0.05),
                    confidence: 0.88
                ),
                DetectedText(
                    text: "Welcome",
                    boundingBox: CGRect(x: 0.5, y: 0.7, width: 0.35, height: 0.06),
                    confidence: 0.92
                ),
                DetectedText(
                    text: "Camera",
                    boundingBox: CGRect(x: 0.4, y: 0.3, width: 0.25, height: 0.05),
                    confidence: 0.90
                )
            ],
            geometrySize: CGSize(width: 390, height: 844)
        )
        
        // Add some UI elements to make it look more realistic
        VStack {
            Spacer()
            Text("Tap a box to translate")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.5)))
                .padding(.bottom, 50)
        }
    }
    .frame(width: 390, height: 844)
}

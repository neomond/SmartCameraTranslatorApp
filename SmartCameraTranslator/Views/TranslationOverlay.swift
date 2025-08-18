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
  @StateObject private var translationService = TranslationService()
  @State private var selectedText: DetectedText?
  @State private var currentTranslation: String = ""
  @State private var isTranslating = false
  
  var body: some View {
    ZStack {
      ForEach(detectedTexts) { detection in
        let rect = detection.convertedBoundingBox(for: geometrySize)
        
        // Bounding box
        RoundedRectangle(cornerRadius: 4)
          .stroke(
            selectedText?.id == detection.id ? Color.green : Color.blue.opacity(0.8),
            lineWidth: selectedText?.id == detection.id ? 3 : 2
          )
          .frame(width: rect.width, height: rect.height)
          .position(x: rect.midX, y: rect.midY)
          .animation(.easeInOut(duration: 0.2), value: selectedText?.id)
          .onTapGesture {
            handleTap(for: detection)
          }
        
        // Always show detected text label
        Text(detection.text)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.blue.opacity(0.8))
          .cornerRadius(6)
          .position(x: rect.midX, y: max(rect.minY - 20, 30))
        
        // Translation bubble (only when selected)
        if selectedText?.id == detection.id {
          TranslationBubble(
            original: detection.text,
            translated: currentTranslation.isEmpty ? "Translating..." : currentTranslation,
            sourceLanguage: translationService.sourceLanguage,
            targetLanguage: translationService.targetLanguage,
            position: CGPoint(x: rect.midX, y: max(rect.minY - 80, 80)), // Ensure it's not off-screen
            isLoading: isTranslating
          )
          .transition(.scale.combined(with: .opacity))
        }
      }
    }
  }
  
  private func handleTap(for detection: DetectedText) {
    // Add haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    impactFeedback.impactOccurred()
    
    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
      if selectedText?.id == detection.id {
        // Toggle off if same text is tapped
        selectedText = nil
        currentTranslation = ""
      } else {
        // Select new text and start translation
        selectedText = detection
        currentTranslation = ""
        isTranslating = true
        
        // Start translation
        Task {
          do {
            let translation = await translationService.translate(detection.text)
            await MainActor.run {
              currentTranslation = translation
              isTranslating = false
            }
          }
        }
      }
    }
  }
}

// Enhanced bubble with language indicators
struct TranslationBubble: View {
  let original: String
  let translated: String
  let sourceLanguage: TranslationModel.Language
  let targetLanguage: TranslationModel.Language
  let position: CGPoint
  let isLoading: Bool
  
  var body: some View {
    VStack(spacing: 8) {
      // Original text with language
      HStack(spacing: 6) {
        Text(sourceLanguage.flag)
          .font(.caption)
        Text(original)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(.white)
          .lineLimit(2)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color.blue)
      .cornerRadius(8)
      
      // Arrow
      Image(systemName: "arrow.down")
        .font(.caption2)
        .foregroundColor(.gray)
      
      // Translated text with language
      HStack(spacing: 6) {
        Text(targetLanguage.flag)
          .font(.caption)
        
        if isLoading {
          ProgressView()
            .scaleEffect(0.8)
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
        } else {
          Text(translated)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .lineLimit(2)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color.green)
      .cornerRadius(8)
    }
    .position(position)
    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
  }
}

#Preview {
  ZStack {
    Rectangle()
      .fill(
        LinearGradient(
          colors: [.black, .gray.opacity(0.8)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .ignoresSafeArea()
    
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
        )
      ],
      geometrySize: CGSize(width: 390, height: 844)
    )
    
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

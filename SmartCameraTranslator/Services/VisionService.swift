//
//  VisionService.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 17.08.25.
//

import Vision
import SwiftUI
import AVFoundation

class VisionService: ObservableObject {
  @Published var detectedTexts: [DetectedText] = []
  @Published var isProcessing = false
  
  private var currentBuffer: CVPixelBuffer?
  private let textRecognitionQueue = DispatchQueue(label: "text.recognition.queue")
  private var lastProcessTime = Date()
  private let processInterval: TimeInterval = 0.5
  
  // Enhanced filtering parameters
  private let minimumConfidence: Float = 0.7
  private let minimumTextLength: Int = 3
  private let minimumTextHeight: CGFloat = 0.04
  
  func processBuffer(_ buffer: CVPixelBuffer) {
    let now = Date()
    guard now.timeIntervalSince(lastProcessTime) >= processInterval else { return }
    lastProcessTime = now
    
    currentBuffer = buffer
    
    textRecognitionQueue.async { [weak self] in
      self?.performTextRecognition(on: buffer)
    }
  }
  
  private func performTextRecognition(on buffer: CVPixelBuffer) {
    let request = VNRecognizeTextRequest { [weak self] request, error in
      guard let self = self,
            let observations = request.results as? [VNRecognizedTextObservation],
            !observations.isEmpty else {
        DispatchQueue.main.async {
          self?.detectedTexts = []
        }
        return
      }
      
      // Enhanced filtering and processing
      let texts = observations.compactMap { observation -> DetectedText? in
        guard let topCandidate = observation.topCandidates(1).first else { return nil }
        
        let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Apply all filters
        guard text.count >= self.minimumTextLength,
              topCandidate.confidence >= self.minimumConfidence,
              observation.boundingBox.height >= self.minimumTextHeight,
              self.isReadableText(text) else { return nil }
        
        return DetectedText(
          text: text,
          boundingBox: observation.boundingBox,
          confidence: topCandidate.confidence
        )
      }
      
      // Sort by confidence and limit results
      let filteredTexts = texts
        .sorted { $0.confidence > $1.confidence }
        .prefix(6)
      
      DispatchQueue.main.async {
        self.detectedTexts = Array(filteredTexts)
        self.isProcessing = !filteredTexts.isEmpty
      }
    }
    
    request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
    request.usesLanguageCorrection = true
    request.minimumTextHeight = Float(minimumTextHeight)
    
    do {
      let handler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
      try handler.perform([request])
    } catch {
      print("Failed to perform text recognition: \(error)")
    }
  }
  
  private func isReadableText(_ text: String) -> Bool {
    // Skip single characters unless they're meaningful words
    if text.count == 1 && !["I", "A", "a"].contains(text) {
      return false
    }
    
    // Must contain at least 50% letters
    let letterCount = text.filter { $0.isLetter }.count
    let totalCount = text.count
    guard Double(letterCount) / Double(totalCount) >= 0.5 else { return false }
    
    // Skip barcode-like patterns
    let barcodePatterns = ["|||", "||||", "----", "====", "123456", "67890"]
    for pattern in barcodePatterns {
      if text.contains(pattern) { return false }
    }
    
    // Skip texts that are mostly numbers (like barcodes)
    let numberCount = text.filter { $0.isNumber }.count
    if Double(numberCount) / Double(totalCount) > 0.8 { return false }
    
    return true
  }
  
  func clearDetections() {
    detectedTexts = []
    isProcessing = false
  }
}

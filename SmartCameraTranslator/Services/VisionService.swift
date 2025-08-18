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
  
  // Add filtering parameters
  private let minimumConfidence: Float = 0.5
  private let minimumTextLength: Int = 2
  
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
      
      // Filter and process texts
      let texts = observations.compactMap { observation -> DetectedText? in
        guard let topCandidate = observation.topCandidates(1).first,
              !topCandidate.string.isEmpty,
              topCandidate.confidence >= self.minimumConfidence,
              topCandidate.string.count >= self.minimumTextLength,
              self.isRelevantText(topCandidate.string) else { return nil }
        
        return DetectedText(
          text: topCandidate.string,
          boundingBox: observation.boundingBox,
          confidence: topCandidate.confidence
        )
      }
      
      // Group nearby texts and take only the most prominent ones
      let groupedTexts = self.groupNearbyTexts(texts)
      
      DispatchQueue.main.async {
        self.detectedTexts = groupedTexts
        self.isProcessing = !groupedTexts.isEmpty
      }
    }
    
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.minimumTextHeight = 0.03 // Increased to filter out tiny text
    
    do {
      let handler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
      try handler.perform([request])
    } catch {
      print("Failed to perform text recognition: \(error)")
    }
  }
  
  // Filter out single characters and symbols
  private func isRelevantText(_ text: String) -> Bool {
    // Skip single characters unless they're meaningful
    if text.count == 1 && !["I", "A"].contains(text) {
      return false
    }
    
    // Skip if it's just symbols/punctuation
    let letters = text.filter { $0.isLetter }
    return !letters.isEmpty
  }
  
  // Group texts that are close together
  private func groupNearbyTexts(_ texts: [DetectedText]) -> [DetectedText] {
    // Take only top 10 largest text areas
    let sortedBySize = texts.sorted {
      ($0.boundingBox.width * $0.boundingBox.height) >
      ($1.boundingBox.width * $1.boundingBox.height)
    }
    
    return Array(sortedBySize.prefix(10))
  }
  
  func clearDetections() {
    detectedTexts = []
    isProcessing = false
  }
}

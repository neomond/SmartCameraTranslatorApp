//
//  VisionService.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 17.08.25.
//

import Vision
import SwiftUI
import AVFoundation

// MARK: - Vision Text Detection Service
class VisionService: ObservableObject {
    // MARK: - Published Properties
    @Published var detectedTexts: [DetectedText] = []
    @Published var isProcessing = false
    
    // MARK: - Private Properties
    private var currentBuffer: CVPixelBuffer?
    private let textRecognitionQueue = DispatchQueue(label: "text.recognition.queue")
    private var lastProcessTime = Date()
    
    // MARK: - Configuration
    private let processInterval: TimeInterval = 0.5
    private let minimumConfidence: Float = 0.7
    private let minimumTextLength: Int = 3
    private let minimumTextHeight: CGFloat = 0.04
    private let maxResults = 6
    
    // MARK: - Main Processing Function
    func processBuffer(_ buffer: CVPixelBuffer) {
        let now = Date()
        guard now.timeIntervalSince(lastProcessTime) >= processInterval else { return }
        lastProcessTime = now
        
        currentBuffer = buffer
        
        textRecognitionQueue.async { [weak self] in
            self?.performTextRecognition(on: buffer)
        }
    }
    
    // MARK: - Text Recognition
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
            
            let detectedTexts = self.processObservations(observations)
            
            DispatchQueue.main.async {
                self.detectedTexts = detectedTexts
                self.isProcessing = !detectedTexts.isEmpty
            }
        }
        
        configureRequest(request)
        
        do {
            let handler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
            try handler.perform([request])
        } catch {
            print("Failed to perform text recognition: \(error)")
        }
    }
    
    // MARK: - Request Configuration
    private func configureRequest(_ request: VNRecognizeTextRequest) {
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = Float(minimumTextHeight)
    }
    
    // MARK: - Observation Processing
    private func processObservations(_ observations: [VNRecognizedTextObservation]) -> [DetectedText] {
        let texts = observations.compactMap { observation -> DetectedText? in
            guard let topCandidate = observation.topCandidates(1).first else { return nil }
            
            let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Apply all filters
            guard isValidText(text, confidence: topCandidate.confidence, boundingBox: observation.boundingBox) else {
                return nil
            }
            
            return DetectedText(
                text: text,
                boundingBox: observation.boundingBox,
                confidence: topCandidate.confidence
            )
        }
        
        // Sort by confidence and limit results
        return Array(texts.sorted { $0.confidence > $1.confidence }.prefix(maxResults))
    }
    
    // MARK: - Text Validation
    private func isValidText(_ text: String, confidence: Float, boundingBox: CGRect) -> Bool {
        // Length check
        guard text.count >= minimumTextLength else { return false }
        
        // Confidence check
        guard confidence >= minimumConfidence else { return false }
        
        // Size check
        guard boundingBox.height >= minimumTextHeight else { return false }
        
        // Content quality check
        return isReadableText(text)
    }
    
    private func isReadableText(_ text: String) -> Bool {
        // Skip meaningless single characters
        if text.count == 1 && !["I", "A", "a"].contains(text) {
            return false
        }
        
        // Must contain at least 50% letters
        let letterCount = text.filter { $0.isLetter }.count
        let totalCount = text.count
        guard Double(letterCount) / Double(totalCount) >= 0.5 else { return false }
        
        // Filter out barcode patterns
        let barcodePatterns = ["|||", "||||", "----", "====", "123456", "67890"]
        for pattern in barcodePatterns {
            if text.contains(pattern) { return false }
        }
        
        // Skip number-heavy text (likely barcodes)
        let numberCount = text.filter { $0.isNumber }.count
        if Double(numberCount) / Double(totalCount) > 0.8 { return false }
        
        return true
    }
    
    // MARK: - Control Functions
    func clearDetections() {
        detectedTexts = []
        isProcessing = false
    }
    
    // MARK: - Configuration Updates
    func updateConfiguration(minConfidence: Float? = nil, minTextLength: Int? = nil, minTextHeight: CGFloat? = nil) {
        // This would allow dynamic configuration updates if needed
        // Implementation would update the private properties and apply immediately
    }
}

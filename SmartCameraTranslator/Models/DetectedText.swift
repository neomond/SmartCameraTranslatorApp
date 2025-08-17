//
//  DetectedText.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 17.08.25.
//

import Foundation
import Vision

struct DetectedText: Identifiable {
  let id: UUID = UUID()
  let text: String
  let boundingBox: CGRect
  let confidence: Float
  
  // MARK: - Convert Vision coordinates to SwiftUI coordinates
  func convertedBoundingBox(for geometry: CGSize) -> CGRect {
    let width = boundingBox.width * geometry.width
    let height = boundingBox.height * geometry.height
    let x = boundingBox.minX * geometry.width
    let y = (1 - boundingBox.maxY) * geometry.height
    
    return CGRect(x: x, y: y, width: width, height: height)
  }
}

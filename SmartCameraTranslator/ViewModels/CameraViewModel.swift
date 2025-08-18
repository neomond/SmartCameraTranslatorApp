//
//  CameraViewModel.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 17.08.25.
//

import SwiftUI
import AVFoundation
import Combine

class CameraViewModel: NSObject, ObservableObject {
  @Published var isAuthorized = false
  @Published var isSessionRunning = false
  
  private let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "camera.session.queue")
  private var videoOutput: AVCaptureVideoDataOutput?
  
  private let visionService = VisionService()
  
  var detectedTexts: [DetectedText] {
    visionService.detectedTexts
  }
  
  var visionServicePublisher: VisionService {
    visionService
  }
  
  var captureSession: AVCaptureSession { session }
  
  override init() {
    super.init()
    checkAuthorization()
  }
  
  func checkAuthorization() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      isAuthorized = true
      setupCamera()
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        DispatchQueue.main.async {
          self?.isAuthorized = granted
          if granted {
            self?.setupCamera()
          }
        }
      }
    default:
      isAuthorized = false
    }
  }
  
  private func setupCamera() {
    sessionQueue.async { [weak self] in
      self?.configureCaptureSession()
    }
  }
  
  private func configureCaptureSession() {
    session.beginConfiguration()
    
    // Add video input
    guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: .back),
          let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
          session.canAddInput(videoInput) else {
      return
    }
    
    session.addInput(videoInput)
    
    // Add video output
    let output = AVCaptureVideoDataOutput()
    output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.output.queue"))
    
    if session.canAddOutput(output) {
      session.addOutput(output)
      videoOutput = output
    }
    
    session.commitConfiguration()
  }
  
  func startSession() {
    sessionQueue.async { [weak self] in
      if !(self?.session.isRunning ?? false) {
        self?.session.startRunning()
        DispatchQueue.main.async {
          self?.isSessionRunning = true
        }
      }
    }
  }
  
  func stopSession() {
    sessionQueue.async { [weak self] in
      if self?.session.isRunning ?? false {
        self?.session.stopRunning()
        DispatchQueue.main.async {
          self?.isSessionRunning = false
        }
      }
    }
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput,
                     didOutput sampleBuffer: CMSampleBuffer,
                     from connection: AVCaptureConnection) {
    
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    visionService.processBuffer(pixelBuffer)
  }
}


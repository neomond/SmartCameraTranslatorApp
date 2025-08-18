//
//  CameraView.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 17.08.25.
//

import SwiftUI
import AVFoundation

//  MARK: - Camera Preview using UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
  let session: AVCaptureSession
  
  func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: .zero)
    
    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = .resizeAspectFill
    view.layer.addSublayer(previewLayer)
    
    context.coordinator.previewLayer = previewLayer
    return view
  }
  
  func updateUIView(_ uiView: UIView, context: Context) {
    context.coordinator.previewLayer?.frame = uiView.bounds
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator()
  }
  
  class Coordinator {
    var previewLayer: AVCaptureVideoPreviewLayer?
  }
}

//  MARK: - Main Camera View
struct CameraView: View {
  @StateObject private var cameraVM = CameraViewModel()
  @State private var showSettings = false
  @State private var isDetecting = true
  
  var body: some View {
    ZStack {
      if cameraVM.isAuthorized {
        GeometryReader { geometry in
          CameraPreviewView(session: cameraVM.captureSession)
            .ignoresSafeArea()
            .onAppear {
              cameraVM.startSession()
            }
            .onDisappear {
              cameraVM.stopSession()
            }
            .overlay(
              // Add translation overlay
              TranslationOverlay(
                detectedTexts: cameraVM.detectedTexts,
                geometrySize: geometry.size
              )
              .allowsHitTesting(true)
            )
        }
        
        // UI Controls overlay
        VStack {
          HStack {
            // Detection toggle
            Button(action: {
              isDetecting.toggle()
              if !isDetecting {
                cameraVM.visionServicePublisher.clearDetections()
              }
            }) {
              Image(systemName: isDetecting ? "eye.fill" : "eye.slash.fill")
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .background(Circle().fill(isDetecting ? Color.blue : Color.gray))
            }
            .padding()
            
            Spacer()
            
            Button(action: { showSettings.toggle() }) {
              Image(systemName: "gear")
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .padding()
          }
          
          Spacer()
          
          // Status indicator
          VStack {
            if !cameraVM.detectedTexts.isEmpty {
              Text("\(cameraVM.detectedTexts.count) text(s) detected")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.green))
                .transition(.scale)
            } else {
              Text("Point camera at text")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.5)))
            }
          }
          .padding(.bottom, 50)
          .animation(.easeInOut, value: cameraVM.detectedTexts.count)
        }
      } else {
          // MARK: - No camera permission view
          VStack(spacing: 20) {
            Image(systemName: "camera.fill")
              .font(.system(size: 60))
              .foregroundColor(.gray)
            
            Text("Camera Access Required")
              .font(.title2)
            
            Text("Please enable camera access in Settings")
              .font(.caption)
              .foregroundColor(.gray)
            
            Button("Open Settings") {
              if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
              }
            }
            .buttonStyle(.borderedProminent)
          }
        }
      }
        .sheet(isPresented: $showSettings) {
          SettingsView()
        }
    }
  }
  
  #Preview {
    CameraView()
  }

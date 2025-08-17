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
  
  var body: some View {
    ZStack {
      if cameraVM.isAuthorized {
        CameraPreviewView(session: cameraVM.captureSession)
          .ignoresSafeArea()
          .onAppear {
            cameraVM.startSession()
          }
          .onDisappear {
            cameraVM.stopSession()
          }
        
        //  MARK: - Overlay UI
        VStack {
          HStack {
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
          
          //  MARK: - Bottom control area
          VStack {
            Text("Point camera at text")
              .font(.caption)
              .foregroundColor(.white)
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(Capsule().fill(Color.black.opacity(0.5)))
          }
          .padding(.bottom, 50)
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

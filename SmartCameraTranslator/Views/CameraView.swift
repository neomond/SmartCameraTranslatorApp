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
    @StateObject private var translationService = JSONTranslationService()
    @StateObject private var speechService = SpeechService.shared
    @State private var showSettings = false
    @State private var isDetecting = true
    @State private var viewMode: CameraViewMode = .detection
    @State private var showModeDescription = false
    
    enum CameraViewMode: String, CaseIterable {
        case detection = "Detection"
        case preview = "Preview"
        
        var icon: String {
            switch self {
            case .detection: return "eye.fill"
            case .preview: return "camera.fill"
            }
        }
        
        var description: String {
            switch self {
            case .detection: return "Text detection active"
            case .preview: return "Clean camera view"
            }
        }
    }
    
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
                            // Only show translation overlay in detection mode
                            Group {
                                if viewMode == .detection && isDetecting {
                                    TranslationOverlay(
                                        detectedTexts: cameraVM.detectedTexts,
                                        geometrySize: geometry.size,
                                        translationService: translationService
                                    )
                                    .allowsHitTesting(true)
                                }
                            }
                        )
                }
                
                // UI Controls overlay
                VStack {
                    // Top controls
                    HStack {
                        // View Mode Toggle
                        Button(action: toggleViewMode) {
                            HStack(spacing: 8) {
                                Image(systemName: viewMode.icon)
                                    .font(.title3)
                                Text(viewMode.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(viewMode == .detection ? Color.blue : Color.green)
                            )
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Settings button
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
                    
                    // Bottom controls
                    VStack(spacing: 12) {
                        // Detection controls (only in detection mode)
                        if viewMode == .detection {
                            HStack(spacing: 16) {
                                // Detection toggle
                                Button(action: toggleDetection) {
                                    HStack(spacing: 6) {
                                        Image(systemName: isDetecting ? "eye.fill" : "eye.slash.fill")
                                            .font(.caption)
                                        Text(isDetecting ? "ON" : "OFF")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(isDetecting ? Color.blue : Color.gray)
                                    )
                                }
                                
                                // Speech toggle
                                Button(action: toggleSpeech) {
                                    HStack(spacing: 6) {
                                        Image(systemName: speechService.isEnabled ? "speaker.2.fill" : "speaker.slash.fill")
                                            .font(.caption)
                                        Text("TTS")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(speechService.isEnabled ? Color.purple : Color.gray)
                                    )
                                }
                                
                                // Quick language switch
                                Button(action: quickLanguageSwitch) {
                                    HStack(spacing: 4) {
                                        Text(translationService.sourceLanguage.flag)
                                        Image(systemName: "arrow.right")
                                            .font(.caption2)
                                        Text(translationService.targetLanguage.flag)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.5))
                                    )
                                }
                            }
                        }
                        
                        // Status indicator
                        VStack {
                            if viewMode == .detection {
                                if !cameraVM.detectedTexts.isEmpty && isDetecting {
                                    Text("\(cameraVM.detectedTexts.count) text(s) detected")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Color.green))
                                        .transition(.scale)
                                } else if isDetecting {
                                    Text("Point camera at text")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Color.black.opacity(0.5)))
                                } else {
                                    Text("Detection paused")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Color.gray))
                                }
                            } else {
                                Text("Preview mode - Clean camera view")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color.green.opacity(0.8)))
                            }
                        }
                        .animation(.easeInOut, value: cameraVM.detectedTexts.count)
                        .animation(.easeInOut, value: viewMode)
                        .animation(.easeInOut, value: isDetecting)
                    }
                    .padding(.bottom, 50)
                }
                
                // Mode description overlay (appears briefly when switching)
                if showModeDescription {
                    VStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: viewMode.icon)
                                .font(.title)
                                .foregroundColor(.white)
                            
                            Text(viewMode.rawValue)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(viewMode.description)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.7))
                                .blur(radius: 1)
                        )
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .scale))
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
            SettingsView(translationService: translationService)
        }
    }
    
    // MARK: - Helper functions
    private func toggleViewMode() {
        HapticService.shared.impact(style: .medium)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            viewMode = viewMode == .detection ? .preview : .detection
        }
        
        // Clear detections when switching to preview mode
        if viewMode == .preview {
            cameraVM.visionServicePublisher.clearDetections()
        }
        
        // Show mode description briefly
        showModeDescription = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showModeDescription = false
            }
        }
    }
    
    private func toggleDetection() {
        HapticService.shared.impact(style: .light)
        
        withAnimation(.easeInOut) {
            isDetecting.toggle()
            if !isDetecting {
                cameraVM.visionServicePublisher.clearDetections()
            }
        }
    }
    
    private func toggleSpeech() {
        HapticService.shared.impact(style: .light)
        speechService.toggleEnabled()
        
        // Stop any current speech when disabling
        if !speechService.isEnabled {
            speechService.stopSpeaking()
        }
    }
    
    private func quickLanguageSwitch() {
        HapticService.shared.selection()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            translationService.switchLanguages()
        }
    }
}

#Preview {
    CameraView()
}

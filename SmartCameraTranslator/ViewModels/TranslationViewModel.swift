//
//  TranslationViewModel.swift
//  SmartCameraTranslator
//
//  Created by Nazrin Atayeva on 17.08.25.
//

import SwiftUI
import Combine

@MainActor
class TranslationViewModel: ObservableObject {
    @Published var translationService = TranslationService()
    @Published var currentTranslation: String = ""
    @Published var isProcessing = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        translationService.$isTranslating
            .assign(to: &$isProcessing)
    }
    
    func translateText(_ text: String) async {
        isProcessing = true
        currentTranslation = await translationService.translate(text)
        isProcessing = false
        
        // Haptic feedback on completion
        await MainActor.run {
            HapticService.shared.notification(type: .success)
        }
    }
    
    func switchLanguages() {
        let temp = translationService.sourceLanguage
        translationService.sourceLanguage = translationService.targetLanguage
        translationService.targetLanguage = temp
        
        HapticService.shared.impact(style: .light)
    }
}

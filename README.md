# Smart Camera Translator App

## Overview

The Smart Camera Translator App is an iOS application built with SwiftUI that leverages the device's camera to detect and translate text in real-time. It's designed to be a handy tool for travelers, language learners, or anyone needing quick translations on the go. The application uses Apple's Vision framework for text recognition and a local JSON-based dictionary for translations.

## Features

-   **Real-time Text Detection**: Utilizes the camera feed to continuously scan and identify text in the environment.
-   **On-Demand Translation**: Tap on any detected text bounding box to get an instant translation.
-   **Multi-language Support**: Supports translation between English, Azerbaijani, Russian, and German.
-   **Local Translation Dictionary**: All translations are performed using an offline dictionary embedded within the app (no internet connection required for core translation).
-   **Translation History**: Keeps a record of recent translations.
-   **Settings**: Allows users to configure source and target languages.
-   **Haptic Feedback**: Provides subtle haptic feedback for user interactions.

## Technologies Used

-   **SwiftUI**: For building the declarative user interface.
-   **AVFoundation**: For camera capture and session management.
-   **Vision Framework**: Apple's framework for performing computer vision tasks, specifically text recognition (`VNRecognizeTextRequest`).
-   **NaturalLanguage Framework**: Used for detecting the dominant language of the input text.
-   **Combine**: For reactive programming and managing state changes.
-   **JSON**: For storing and managing the translation dictionary locally.

## Project Structure

The project is organized into the following main directories:

-   `Models/`: Data structures like `DetectedText.swift` and `TranslationModel.swift`.
-   `Resources/`: Assets (`Assets.xcassets`) and the `translations.json` dictionary.
-   `Services/`: Core logic for `HapticService.swift`, `TranslationService.swift`, and `VisionService.swift`.
-   `ViewModels/`: View-specific logic like `CameraViewModel.swift` and `TranslationViewModel.swift`.
-   `Views/`: SwiftUI views such as `CameraView.swift`, `TranslationOverlay.swift`, `SettingsView.swift`, and `LanguageDownloadView.swift`.
-   `SmartCameraTranslatorApp.swift`: The main entry point of the application.


## Contributing

Contributions are welcome! Please feel free to open issues or submit pull requests.

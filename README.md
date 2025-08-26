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

## Setup and Installation

To run this project, you will need Xcode installed on your macOS system.

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/SmartCameraTranslatorApp.git
    cd SmartCameraTranslatorApp
    ```
    (Note: Replace `yourusername/SmartCameraTranslatorApp.git` with your actual repository URL if it's hosted.)

2.  **Open the project in Xcode**:
    ```bash
    open SmartCameraTranslator.xcodeproj
    ```

3.  **Ensure camera permissions**:
    The app requires camera access. Make sure your iOS device or simulator has camera permissions enabled for the app.

4.  **Run the app**:
    Select a target device (simulator or physical device) and run the app from Xcode.

## Usage

1.  **Launch the app**: The app will open directly to the camera view.
2.  **Point at text**: The app will automatically detect text in the camera feed. Bounding boxes will appear around detected words or phrases.
3.  **Translate**: Tap on a bounding box to see its translation appear in a bubble above the original text.
4.  **Settings**: Tap the gear icon to access settings, where you can change the source and target languages.
5.  **Toggle Detection**: Use the eye icon to enable or disable text detection.

## Future Enhancements (Suggested)

-   **Speech Output for Translations**: Add a feature to vocalize the translated text.
-   **Save/Bookmark Translations**: Allow users to save important translations for quick access.
-   **Manual Text Input**: Implement a feature to manually type or paste text for translation.
-   **Expanded Dictionary**: Continuously grow the `translations.json` dictionary with more words and phrases.
-   **On-device Machine Learning Translation**: Explore integrating more advanced on-device ML models for translation beyond dictionary lookups for more robust and comprehensive translation capabilities.

## Contributing

Contributions are welcome! Please feel free to open issues or submit pull requests.

## License

[Specify your license here, e.g., MIT, Apache 2.0, etc.]

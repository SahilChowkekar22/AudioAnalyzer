# AudioAnalyzer  
**An On-Device Speech & Sound Classification App for iOS (Swift 6, SwiftUI, Core ML, AVFoundation, Speech)**  

AudioAnalyzer demonstrates **live and file-based audio analysis** using Apple’s built-in **Speech Recognition** and **SoundAnalysis** frameworks.  
It processes real-time microphone input or imported audio files to generate:  
- **Speech transcriptions (SFSpeechRecognizer)**  
- **Top sound classifications (SNAudioStreamAnalyzer)**  
- **Structured logging of analysis results (JSON logs)**  

---

## Features

| Feature | Description |
|----------|--------------|
| **Live Audio Analysis** | Streams microphone input, performs real-time speech-to-text and sound classification. |
| **File-based Analysis** | Imports `.m4a` / `.mp3` / `.wav` files for offline transcription and sound classification. |
| **On-device Speech Recognition** | Uses Apple’s built-in neural models (SFSpeechRecognizer) — no network calls. |
| **Sound Classification** | Powered by SoundAnalysis with Apple’s default classifier (`.version1`). |
| **Structured Logging** | Automatically logs analysis results to `analysis_log.json` in the app’s Documents directory. |
| **Thread-safe Data Pipeline** | Swift 6 concurrency-safe using actors & isolation for streaming audio buffers. |
| **Comprehensive Unit Tests** | Fully tested view models, services, and concurrency safety. |

---

##  Project Architecture

The app follows a **Clean MVVM-Coordinator** structure.


 - AudioAnalyzerApp.swift

 - ContentView.swift

- Coordinator

   - AudioAnalyzerCoordinator.swift

   - CoordinatorRegistry.swift

- Managers

   - AudioAnalysisLogger.swift

   - AudioFileAnalyzer.swift

   - LiveAudioAnalyzer.swift

   - SoundClassificationService.swift

   - SpeechRecognitionService.swift

- Models

   - AudioAnalysisModels.swift

- Views

   - AudioAnalyzerView.swift

- ViewModels

   - AudioAnalyzerViewModel.swift


- AudioAnalyzerTests

   - AudioAnalyzerViewModelTests.swift

   - SoundClassificationServiceTests.swift

   - AudioAnalyzerMocks.swift

   - XCTest+AsyncHelpers.swift


---

## Core Frameworks

| Framework | Purpose |
|------------|----------|
| **AVFoundation** | Captures and manages microphone input. |
| **SoundAnalysis** | Classifies environmental sounds (e.g., speech, applause, etc.). |
| **Speech** | Converts spoken words to text via on-device models. |
| **Combine** | Reactive state updates between ViewModel and SwiftUI views. |
| **Swift Concurrency (async/await, actors)** | Safely handles audio streaming, recognition tasks, and UI updates. |
| **CoreML** | (Optional future extension) Integrates with custom `.mlmodelc` classifiers. |

---

## How It Works

### 1. Live Analysis Flow
```swift
AudioAnalyzerView → AudioAnalyzerViewModel → LiveAudioAnalyzer
   ├── SpeechRecognitionService  → SFSpeechRecognizer
   └── SoundClassificationService → SNAudioStreamAnalyzer
```

- Captures live microphone audio with AVAudioEngine

- Streams audio buffers to:

   - SpeechRecognitionService → Transcribes speech

   - SoundClassificationService → Detects sound types

- Updates the AudioAnalyzerViewModel in real time.

### 2. File Analysis Flow

```swift
AudioFileAnalyzer
   ├── transcribeFile(at:) → SpeechRecognitionService
   └── classifyFile(at:)   → SoundClassificationService

```
- Runs asynchronously with async let for parallel speech + sound tasks.

- Combines results into a unified AudioFileAnalysisResult.

### 3. Logging Flow

```swift
AudioAnalysisLogger → analysis_log.json
```

## Testing

### Unit Tests

TestTargets:
  - name: AudioAnalyzerViewModelTests
    description: "Verifies state transitions, error handling, and logging."

  - name: SoundClassificationServiceTests
    description: "Validates analyzer responses and request handling."

  - name: AudioFileAnalyzerTests
    description: "Checks parallel async classification and transcription."

  - name: AudioAnalysisLoggerTests
    description: "Ensures file writes and read consistency."

### UI Tests

   - Simulates live session toggling and file import using AudioAnalyzerUITestsLaunchTests.


## How to Run

1. **Clone this repository**
   ```bash
   git clone https://github.com/SahilChowkekar22/AudioAnalyzer.git
   cd AudioAnalyzer
   ```
2. **Open the project**
   - Open ```AudioAnalyzer.xcodeproj``` in Xcode.

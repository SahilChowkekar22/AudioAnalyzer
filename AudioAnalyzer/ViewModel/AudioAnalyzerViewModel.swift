//
//  AudioAnalyzerViewModel.swift
//  AudioAnalyzer
//
//  Created by Sahil ChowKekar on 11/12/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - View State

/// Represents the current UI and analysis state of the audio analyzer screen.
struct AudioAnalyzerViewState {
    enum Source: Equatable {
        case none
        case file(name: String)
        case live
    }

    var source: Source = .none
    var transcription: String = ""
    var classifications: [AudioClassificationResult] = []
    var isAnalyzingFile = false
    var isRecordingLive = false
    var message: Message?

    enum Message: Equatable {
        case info(String)
        case error(String)
    }
}

// MARK: - ViewModel

@MainActor
final class AudioAnalyzerViewModel: ObservableObject {

    // MARK: Published State
    @Published private(set) var state = AudioAnalyzerViewState()

    // MARK: Dependencies
    private let speechService: SpeechRecognitionServicing
    private let fileAnalyzer: AudioFileAnalyzing
    private let liveAnalyzer: LiveAudioAnalyzing
    private let logger: AudioAnalysisLogging
    private let now: () -> Date

    // Live session control
    private var liveSession: LiveAudioSessionControlling?

    // MARK: Initialization
    init(
        speechService: SpeechRecognitionServicing = SpeechRecognitionService(),
        fileAnalyzer: AudioFileAnalyzing = AudioFileAnalyzer(),
        liveAnalyzer: LiveAudioAnalyzing = LiveAudioAnalyzer(),
        logger: AudioAnalysisLogging = AudioAnalysisLogger(),
        now: @escaping () -> Date = Date.init
    ) {
        self.speechService = speechService
        self.fileAnalyzer = fileAnalyzer
        self.liveAnalyzer = liveAnalyzer
        self.logger = logger
        self.now = now
    }

    // MARK: - Public API

    func binding<Value>(_ keyPath: WritableKeyPath<AudioAnalyzerViewState, Value>) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.state[keyPath: keyPath] = $0 }
        )
    }

    // MARK: File Analysis

    func analyzeFile(at url: URL) async {
        startFileAnalysis(for: url)

        do {
            try await speechService.ensureSpeechAuthorization()
            let result = try await fileAnalyzer.analyzeFile(at: url)
            completeFileAnalysis(with: result)
            try await logAnalysis(
                source: .file,
                transcription: result.transcription,
                classifications: result.classifications
            )
        } catch {
            failFileAnalysis(with: error)
        }
    }

    // MARK: Live Analysis

    func toggleLiveAnalysis() {
        if let session = liveSession {
            session.stop()
            liveSession = nil
            updateState { $0.isRecordingLive = false }
            return
        }

        Task {
            do {
                try await speechService.ensurePermissions()
                startLiveSession()

                let handlers = LiveAudioHandlers(
                    onTranscription: { [weak self] text in
                        Task { @MainActor in self?.updateTranscription(text) }
                    },
                    onClassifications: { [weak self] results in
                        Task { @MainActor in self?.updateClassifications(results) }
                    },
                    onError: { [weak self] error in
                        Task { @MainActor in self?.handleLiveError(error) }
                    },
                    onCompletion: { [weak self] transcript, results in
                        Task { @MainActor in
                            await self?.finishLiveSession(transcript: transcript, results: results)
                        }
                    }
                )

                liveSession = try liveAnalyzer.start(handlers: handlers)
            } catch {
                handleLiveError(error)
            }
        }
    }

    // MARK: - Private State Management

    private func startFileAnalysis(for url: URL) {
        updateState {
            $0.source = .file(name: url.lastPathComponent)
            $0.transcription = ""
            $0.classifications = []
            $0.isAnalyzingFile = true
            $0.message = nil
        }
    }

    private func completeFileAnalysis(with result: AudioFileAnalysisResult) {
        updateState {
            $0.transcription = result.transcription
            $0.classifications = result.classifications
            $0.isAnalyzingFile = false
            $0.message = .info("File analysis completed successfully.")
        }
    }

    private func failFileAnalysis(with error: Error) {
        updateState {
            $0.isAnalyzingFile = false
            $0.classifications = []
            $0.message = .error(userFriendlyMessage(for: error))
        }
    }

    private func startLiveSession() {
        updateState {
            $0.source = .live
            $0.transcription = ""
            $0.classifications = []
            $0.isRecordingLive = true
            $0.message = .info("🎙 Listening…")
        }
    }

    private func updateTranscription(_ text: String) {
        updateState { $0.transcription = text }
    }

    private func updateClassifications(_ results: [AudioClassificationResult]) {
        updateState { $0.classifications = results }
    }

    private func handleLiveError(_ error: Error) {
        updateState {
            $0.isRecordingLive = false
            $0.message = .error(userFriendlyMessage(for: error))
        }
        liveSession?.cancel()
        liveSession = nil
    }

    private func finishLiveSession(transcript: String, results: [AudioClassificationResult]) async {
        updateState {
            $0.isRecordingLive = false
            $0.transcription = transcript
            $0.classifications = results
            $0.message = results.isEmpty ? .info("No sounds detected.") : .info("Live analysis stopped.")
        }

        liveSession = nil

        guard !transcript.isEmpty || !results.isEmpty else { return }

        try? await logAnalysis(
            source: .live,
            transcription: transcript,
            classifications: results
        )
    }

    // MARK: - Logging

    private func logAnalysis(
        source: AudioAnalysisSource,
        transcription: String,
        classifications: [AudioClassificationResult]
    ) async throws {
        let entry = AudioAnalysisLogEntry(
            id: UUID(),
            timestamp: now(),
            source: source,
            transcription: transcription,
            classifications: classifications
        )
        try await logger.log(entry: entry)
    }

    // MARK: - Utility

    private func userFriendlyMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return error.localizedDescription
    }

    private func updateState(_ block: (inout AudioAnalyzerViewState) -> Void) {
        block(&state)
    }
}

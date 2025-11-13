//
//  AudioAnalyzerMocks.swift
//  AudioAnalyzerTests
//
//  Created by Sahil ChowKekar on 11/12/25.
//

import XCTest
import Speech
import SoundAnalysis
@testable import AudioAnalyzer

final class MockSpeechService: SpeechRecognitionServicing {
    var didRequestPermission = false
    var shouldFail = false
    var returnedText = "Hello world"

    func ensureSpeechAuthorization() async throws {}
    func ensurePermissions() async throws {
        didRequestPermission = true
        if shouldFail { throw SpeechRecognitionError.permissionDenied }
    }
    func transcribeFile(at url: URL) async throws -> String {
        if shouldFail { throw SpeechRecognitionError.transcriptionFailed }
        return returnedText
    }
    func makeRecognizer() throws -> SFSpeechRecognizer { SFSpeechRecognizer()! }
}

final class MockSoundService: SoundClassificationServicing {
    var shouldFail = false
    func classifyFile(at url: URL) async throws -> [AudioClassificationResult] {
        if shouldFail { throw SoundClassificationError.analysisFailed }
        return [AudioClassificationResult(identifier: "Speech", confidence: 0.9)]
    }
    func makeStreamAnalyzer(observing observer: SNResultsObserving, format: AVAudioFormat) throws -> SNAudioStreamAnalyzer {
        SNAudioStreamAnalyzer(format: format)
    }
}

final class MockLogger: AudioAnalysisLogging {
    private(set) var loggedEntries: [AudioAnalysisLogEntry] = []
    func log(entry: AudioAnalysisLogEntry) async throws {
        loggedEntries.append(entry)
    }
}

final class SafeMockFileAnalyzer: AudioFileAnalyzing {
    func analyzeFile(at url: URL) async throws -> AudioFileAnalysisResult {
        AudioFileAnalysisResult(
            transcription: "Hello world",
            classifications: [AudioClassificationResult(identifier: "Speech", confidence: 0.9)]
        )
    }
}

final class DummyLiveAnalyzer: LiveAudioAnalyzing {
    func start(handlers: LiveAudioHandlers) throws -> LiveAudioSessionControlling {
        DummyLiveSession(handlers: handlers)
    }
}

final class DummyLiveSession: LiveAudioSessionControlling {
    private let handlers: LiveAudioHandlers
    init(handlers: LiveAudioHandlers) { self.handlers = handlers }
    func stop() { handlers.onCompletion("Stopped", []) }
    func cancel() {}
}

final class DummyFileAnalyzer: AudioFileAnalyzing {
    func analyzeFile(at url: URL) async throws -> AudioFileAnalysisResult {
        AudioFileAnalysisResult(
            transcription: "dummy transcript",
            classifications: [AudioClassificationResult(identifier: "speech", confidence: 0.9)]
        )
    }
}

final class FailingMockFileAnalyzer: AudioFileAnalyzing {
    func analyzeFile(at url: URL) async throws -> AudioFileAnalysisResult {
        throw AudioFileAnalysisError.invalidFile
    }
}


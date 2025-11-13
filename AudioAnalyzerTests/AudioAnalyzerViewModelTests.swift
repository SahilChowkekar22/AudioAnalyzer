//
//  AudioAnalyzerViewModelTests.swift
//  AudioAnalyzerTests
//
//  Created by Sahil ChowKekar on 11/12/25.
//

import XCTest
@testable import AudioAnalyzer

final class AudioAnalyzerViewModelTests: XCTestCase {

    func testAnalyzeFile_Success() async throws {
        let mockSpeech = MockSpeechService()
        let mockSound = MockSoundService()
        let mockLogger = MockLogger()
        let analyzer = SafeMockFileAnalyzer()

        let sut = await AudioAnalyzerViewModel(
            speechService: mockSpeech,
            fileAnalyzer: analyzer,
            liveAnalyzer: DummyLiveAnalyzer(),
            logger: mockLogger
        )

        await sut.analyzeFile(at: URL(fileURLWithPath: "/tmp/fake.m4a"))
        let successState = await MainActor.run { sut.state }

        XCTAssertEqual(successState.transcription, "Hello world")
        XCTAssertEqual(successState.classifications.first?.identifier, "Speech")
        XCTAssertTrue(mockLogger.loggedEntries.count > 0)
    }

    func testAnalyzeFile_Fails_Gracefully() async {
        let mockSpeech = MockSpeechService()
        mockSpeech.shouldFail = true
        let mockSound = MockSoundService()
        let mockLogger = MockLogger()

//        let analyzer = AudioFileAnalyzer(speechService: mockSpeech, classificationService: mockSound)
        let analyzer = FailingMockFileAnalyzer()
        let sut = await AudioAnalyzerViewModel(
            speechService: mockSpeech,
            fileAnalyzer: analyzer,
            liveAnalyzer: DummyLiveAnalyzer(),
            logger: mockLogger
        )

        await sut.analyzeFile(at: URL(fileURLWithPath: "/tmp/broken.m4a"))

        let (errorText, classifications) = await MainActor.run { () -> (String?, [AudioClassificationResult]) in
            let state = sut.state
            switch state.message {
            case .error(let msg): return (msg, state.classifications)
            default: return (nil, state.classifications)
            }
        }

        guard let msg = errorText else {
            XCTFail("Expected error message but got nil")
            return
        }
        XCTAssertTrue(!msg.isEmpty, "Expected a non-empty error message")
        XCTAssertTrue(classifications.isEmpty)
    }

    func testToggleLiveAnalysis_StartAndStop() async throws {
        let mockSpeech = MockSpeechService()
        let mockLogger = MockLogger()
        let sut = await AudioAnalyzerViewModel(
            speechService: mockSpeech,
            fileAnalyzer: DummyFileAnalyzer(),
            liveAnalyzer: DummyLiveAnalyzer(),
            logger: mockLogger
        )

        await sut.toggleLiveAnalysis()
        try await Task.sleep(nanoseconds: 300_000_000)
        await sut.toggleLiveAnalysis()

        let isRecording = await MainActor.run { sut.state.isRecordingLive }
        XCTAssertFalse(isRecording)
    }
}

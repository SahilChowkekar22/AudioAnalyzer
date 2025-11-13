//
//  AudioFileAnalyzer.swift
//  AudioAnalyzer
//
//  Created by Sahil ChowKekar on 11/24/25.
//

import Foundation

protocol AudioFileAnalyzing {
    func analyzeFile(at url: URL) async throws -> AudioFileAnalysisResult
}

enum AudioFileAnalysisError: LocalizedError {
    case invalidFile

    var errorDescription: String? {
        "The selected audio file could not be analyzed."
    }
}

final class AudioFileAnalyzer: AudioFileAnalyzing {
    private let speechService: SpeechRecognitionServicing
    private let classificationService: SoundClassificationServicing

    init(
        speechService: SpeechRecognitionServicing = SpeechRecognitionService(),
        classificationService: SoundClassificationServicing = SoundClassificationService()
    ) {
        self.speechService = speechService
        self.classificationService = classificationService
    }

    func analyzeFile(at url: URL) async throws -> AudioFileAnalysisResult {
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw AudioFileAnalysisError.invalidFile
        }

        do {
            let transcription = try await speechService.transcribeFile(at: url)
            let classifications = try await classificationService.classifyFile(at: url)
            return AudioFileAnalysisResult(
                transcription: transcription,
                classifications: classifications
            )
        } catch {
            throw error  // ✅ ensures the mock error is propagated
        }
    }


}

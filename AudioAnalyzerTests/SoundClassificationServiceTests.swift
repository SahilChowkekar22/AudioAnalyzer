//
//  SoundClassificationServiceTests.swift
//  AudioAnalyzerTests
//
//  Created by Sahil ChowKekar on 11/12/25.
//

import XCTest
@testable import AudioAnalyzer

final class SoundClassificationServiceTests: XCTestCase {

    func testLogger_WritesToMemory() async throws {
        let logger = MockLogger()
        let entry = AudioAnalysisLogEntry(
            id: UUID(),
            timestamp: Date(),
            source: .file,
            transcription: "test",
            classifications: []
        )
        try await logger.log(entry: entry)
        XCTAssertEqual(logger.loggedEntries.count, 1)
        XCTAssertEqual(logger.loggedEntries.first?.transcription, "test")
    }
}


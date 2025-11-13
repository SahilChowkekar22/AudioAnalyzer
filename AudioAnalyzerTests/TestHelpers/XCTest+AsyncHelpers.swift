//
//  XCTest+AsyncHelpers.swift
//  AudioAnalyzerTests
//
//  Created by Sahil ChowKekar on 11/12/25.
//

import XCTest

extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(
        _ expression: @autoclosure @escaping () async throws -> T,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected throw but succeeded. \(message)", file: file, line: line)
        } catch {
            XCTAssertNotNil(error, "Expected non-nil error", file: file, line: line)
        }
    }
}

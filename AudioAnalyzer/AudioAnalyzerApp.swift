//
//  AudioAnalyzerApp.swift
//  AudioAnalyzer
//
//  Created by Sahil ChowKekar on 11/12/25.
//

import SwiftUI

@main
struct AudioAnalyzerApp: App {
    @StateObject private var viewModel = AudioAnalyzerViewModel()

    var body: some Scene {
        WindowGroup {
            AudioAnalyzerView(viewModel: viewModel)
        }
    }
}

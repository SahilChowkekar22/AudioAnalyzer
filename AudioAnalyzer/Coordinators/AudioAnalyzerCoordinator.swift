//
//  AudioAnalyzerCoordinator.swift
//  AudioAnalyzer
//
//  Created by Sahil ChowKekar on 11/24/25.
//

import Foundation

final class AudioAnalyzerCoordinator: ViewModelCoordinating {
    typealias ViewModel = AudioAnalyzerViewModel

    func makeViewModel() -> AudioAnalyzerViewModel {
        AudioAnalyzerViewModel()
    }
}

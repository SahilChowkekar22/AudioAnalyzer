//
//  AudioAnalyzerView.swift
//  AudioAnalyzer
//
//  Created by Sahil ChowKekar on 11/13/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct AudioAnalyzerView: View {
    @StateObject private var viewModel: AudioAnalyzerViewModel
    @State private var isFileImporterPresented = false
    @State private var alertItem: AlertItem?

    init(viewModel: AudioAnalyzerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            
            LinearGradient(
                colors: [.indigo.opacity(0.8), .black.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay(
                RadialGradient(colors: [.purple.opacity(0.3), .clear],
                               center: .bottomTrailing, startRadius: 20, endRadius: 500)
            )

            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    controlButtons
                    transcriptionCard
                    classificationCard
                    messageFooter
                }
                .padding(.horizontal, 28)
                .padding(.top, 50)
                .padding(.bottom, 60)
            }
        }
        .alert(item: $alertItem) { item in
            Alert(
                title: Text(item.title),
                message: Text(item.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.mpeg4Audio, .audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                handleImportedFile(url)
            case .failure(let error):
                alertItem = AlertItem(title: "File Import", message: error.localizedDescription)
            }
        }
    }


    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Audio Analyzer")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("Transcribe & Classify Sounds")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))

            if viewModel.state.isAnalyzingFile || viewModel.state.isRecordingLive {
                ProgressView()
                    .tint(.cyan)
                    .scaleEffect(1.3)
                    .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }


    private var controlButtons: some View {
        HStack(spacing: 20) {
            Button {
                isFileImporterPresented = true
            } label: {
                ControlCard(icon: "doc.text.magnifyingglass",
                            title: "Analyze File",
                            gradient: [.cyan, .teal])
            }
            .disabled(viewModel.state.isAnalyzingFile)

            Button {
                viewModel.toggleLiveAnalysis()
            } label: {
                ControlCard(icon: viewModel.state.isRecordingLive ? "stop.circle.fill" : "waveform.circle.fill",
                            title: viewModel.state.isRecordingLive ? "Stop Live" : "Live Mic",
                            gradient: viewModel.state.isRecordingLive ? [.red, .pink] : [.green, .mint])
                    .overlay(
                        Circle()
                            .stroke(viewModel.state.isRecordingLive ? Color.red.opacity(0.5) : Color.green.opacity(0.5), lineWidth: 6)
                            .scaleEffect(viewModel.state.isRecordingLive ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.state.isRecordingLive)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }


    private var transcriptionCard: some View {
        CardView(title: "Transcription", icon: "text.bubble") {
            if viewModel.state.transcription.isEmpty {
                Text("Transcripts will appear here once analysis begins.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                Text(viewModel.state.transcription)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
            }
        }
    }


    private var classificationCard: some View {
        CardView(title: "Top Predictions", icon: "chart.bar") {
            if viewModel.state.classifications.isEmpty {
                Text("No predictions yet.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 14) {
                    ForEach(viewModel.state.classifications, id: \.identifier) { result in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(result.identifier.capitalized)
                                    .font(.headline)
                                    .foregroundStyle(
                                        LinearGradient(colors: [.cyan, .purple],
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing)
                                    )
                                Spacer()
                                Text(String(format: "%.1f%%", result.confidence * 100))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            GeometryReader { proxy in
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 8)
                                    .overlay(
                                        Capsule()
                                            .fill(
                                                LinearGradient(colors: [.cyan, .purple],
                                                               startPoint: .leading,
                                                               endPoint: .trailing)
                                            )
                                            .frame(width: proxy.size.width * CGFloat(max(0.05, result.confidence)))
                                    )
                            }
                            .frame(height: 8)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - FOOTER

    private var messageFooter: some View {
        if let message = viewModel.state.message {
            switch message {
            case .info(let text):
                return AnyView(
                    Text(text)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 8)
                )
            case .error(let text):
                return AnyView(
                    Text(text)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                )
            }
        } else {
            return AnyView(EmptyView())
        }
    }



    private func handleImportedFile(_ url: URL) {
        do {
            let accessibleURL = try prepareFileURL(url)
            Task { await viewModel.analyzeFile(at: accessibleURL) }
        } catch {
            alertItem = AlertItem(title: "File Import", message: error.localizedDescription)
        }
    }

    private func prepareFileURL(_ url: URL) throws -> URL {
        let fileManager = FileManager.default
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            return try copyToTemporaryDirectory(url: url, fileManager: fileManager)
        } else if url.isFileURL {
            return try copyToTemporaryDirectory(url: url, fileManager: fileManager)
        }
        throw AudioFileAnalysisError.invalidFile
    }

    private func copyToTemporaryDirectory(url: URL, fileManager: FileManager) throws -> URL {
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString + "-" + url.lastPathComponent)
        try fileManager.removeItemIfNeeded(at: tempURL)
        try fileManager.copyItem(at: url, to: tempURL)
        return tempURL
    }
}

private extension FileManager {
    func removeItemIfNeeded(at url: URL) throws {
        if fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
    }
}

// MARK: - Components

private struct ControlCard: View {
    let icon: String
    let title: String
    let gradient: [Color]

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: gradient.first!.opacity(0.4), radius: 8, y: 5)
    }
}

private struct CardView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }
            Divider().background(Color.white.opacity(0.15))
            content
        }
        .padding(20)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.15)))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}

private struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}


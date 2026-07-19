//
//  TabOneView.swift
//  trayapp
//
//  Created by git on 7/18/26.
//

import SwiftUI

struct TabOneContent: View {
    @StateObject private var viewModel = TabOneViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Display")
                    .font(.title)
                Text("Powered by Rust FFI")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Slider(value: $viewModel.brightness, in: 1...100, step: 1)
                .tint(.gray)
                .onChange(of: viewModel.brightness) { _, _ in
                    guard !viewModel.isApplyingPreset else { return }
                    viewModel.applyCurrentSettings()
                }

            Slider(value: $viewModel.redLevel, in: 0...100, step: 1)
                .tint(.red)
                .onChange(of: viewModel.redLevel) { _, _ in
                    guard !viewModel.isApplyingPreset else { return }
                    viewModel.applyCurrentSettings()
                }

            Slider(value: $viewModel.greenLevel, in: 0...100, step: 1)
                .tint(.green)
                .onChange(of: viewModel.greenLevel) { _, _ in
                    guard !viewModel.isApplyingPreset else { return }
                    viewModel.applyCurrentSettings()
                }

            Slider(value: $viewModel.blueLevel, in: 0...100, step: 1)
                .tint(.blue)
                .onChange(of: viewModel.blueLevel) { _, _ in
                    guard !viewModel.isApplyingPreset else { return }
                    viewModel.applyCurrentSettings()
                }

            HStack {
                Button("Full") { viewModel.applyFullPreset() }
                Button("Red") { viewModel.applyRedPreset() }
                Button("Green") { viewModel.applyGreenPreset() }
                Button("Blue") { viewModel.applyBluePreset() }
                Spacer()
                Button("Reset") { viewModel.resetDisplay() }
            }
            .buttonStyle(.bordered)

            Text(viewModel.statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .onAppear {
            viewModel.startDaemon()
        }
    }
}

#if DEBUG
struct TabOneContent_Previews: PreviewProvider {
    static var previews: some View {
        TabOneContent()
    }
}
#endif

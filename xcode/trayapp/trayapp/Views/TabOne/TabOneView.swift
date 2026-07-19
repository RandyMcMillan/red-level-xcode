//
//  TabOneView.swift
//  trayapp
//
//  Created by git on 7/18/26.
//

import RustyLib
import SwiftUI

private enum ChannelPreset: String, CaseIterable, Identifiable {
    case red = "Red"
    case green = "Green"
    case blue = "Blue"
    case custom = "Custom"

    var id: String { rawValue }
}

struct TabOneContent: View {
    @AppStorage("customBrightness") private var savedCustomBrightness: Double = 100
    @AppStorage("customRedLevel") private var savedCustomRedLevel: Double = 100
    @AppStorage("customGreenLevel") private var savedCustomGreenLevel: Double = 100
    @AppStorage("customBlueLevel") private var savedCustomBlueLevel: Double = 100
    @AppStorage("redBrightness") private var savedRedBrightness: Double = 100
    @AppStorage("redRedLevel") private var savedRedRedLevel: Double = 100
    @AppStorage("redGreenLevel") private var savedRedGreenLevel: Double = 0
    @AppStorage("redBlueLevel") private var savedRedBlueLevel: Double = 0
    @AppStorage("greenBrightness") private var savedGreenBrightness: Double = 100
    @AppStorage("greenRedLevel") private var savedGreenRedLevel: Double = 0
    @AppStorage("greenGreenLevel") private var savedGreenGreenLevel: Double = 100
    @AppStorage("greenBlueLevel") private var savedGreenBlueLevel: Double = 0
    @AppStorage("blueBrightness") private var savedBlueBrightness: Double = 100
    @AppStorage("blueRedLevel") private var savedBlueRedLevel: Double = 0
    @AppStorage("blueGreenLevel") private var savedBlueGreenLevel: Double = 0
    @AppStorage("blueBlueLevel") private var savedBlueBlueLevel: Double = 100
    @State private var brightness: Double = 100
    @State private var redLevel: Double = 100
    @State private var greenLevel: Double = 100
    @State private var blueLevel: Double = 100
    @State private var preset: ChannelPreset = .custom
    @State private var isApplyingPreset = false
    @State private var statusMessage = "Ready"

    var body: some View {
        NavigationStack {
            Form {
                Section("Brightness") {
                    Slider(value: $brightness, in: 1...100, step: 1)
                        .tint(.gray)
                        .onChange(of: brightness) { _, _ in
                            guard !isApplyingPreset else { return }
                            saveCurrentPresetSettings()
                            applyCurrentSettings()
                        }
                }

                Section("Channel preset") {
                    Picker("Preset", selection: $preset) {
                        ForEach(ChannelPreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("") {
                    Slider(value: $redLevel, in: 0...100, step: 1)
                        .tint(.red)
                        .onChange(of: redLevel) { _, _ in
                            guard !isApplyingPreset else { return }
                            saveCurrentPresetSettings()
                            applyCurrentSettings()
                        }

                    Slider(value: $greenLevel, in: 0...100, step: 1)
                        .tint(.green)
                        .onChange(of: greenLevel) { _, _ in
                            guard !isApplyingPreset else { return }
                            saveCurrentPresetSettings()
                            applyCurrentSettings()
                        }

                    Slider(value: $blueLevel, in: 0...100, step: 1)
                        .tint(.blue)
                        .onChange(of: blueLevel) { _, _ in
                            guard !isApplyingPreset else { return }
                            saveCurrentPresetSettings()
                            applyCurrentSettings()
                        }

                    HStack {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Divider()
                        Spacer()
                        Button("Reset") {
                            resetButtonTapped()
                        }
                    }
                }
            }
        }
        .onAppear() {
            restoreCustomSettings()
            startDaemon()
        }
        .onChange(of: preset) { _, newPreset in
            applyPreset(newPreset)
        }
    }

    private func applyPreset(_ preset: ChannelPreset) {
        isApplyingPreset = true
        switch preset {
        case .red:
            restoreRedSettings()
        case .green:
            restoreGreenSettings()
        case .blue:
            restoreBlueSettings()
        case .custom:
            restoreCustomSettings()
        }
        applyCurrentSettings()
        DispatchQueue.main.async {
            isApplyingPreset = false
        }
    }

    private func applyCurrentSettings() {
        performRustAction("Applied display settings") {
            applyDisplay(
                brightness: UInt8(brightness),
                red: UInt8(redLevel),
                green: UInt8(greenLevel),
                blue: UInt8(blueLevel)
            )
        }
    }

    private func restoreCustomSettings() {
        brightness = savedCustomBrightness
        redLevel = savedCustomRedLevel
        greenLevel = savedCustomGreenLevel
        blueLevel = savedCustomBlueLevel
    }

    private func saveCustomSettings() {
        savedCustomBrightness = brightness
        savedCustomRedLevel = redLevel
        savedCustomGreenLevel = greenLevel
        savedCustomBlueLevel = blueLevel
    }

    private func restoreRedSettings() {
        brightness = savedRedBrightness
        redLevel = savedRedRedLevel
        greenLevel = savedRedGreenLevel
        blueLevel = savedRedBlueLevel
    }

    private func saveRedSettings() {
        savedRedBrightness = brightness
        savedRedRedLevel = redLevel
        savedRedGreenLevel = greenLevel
        savedRedBlueLevel = blueLevel
    }

    private func restoreGreenSettings() {
        brightness = savedGreenBrightness
        redLevel = savedGreenRedLevel
        greenLevel = savedGreenGreenLevel
        blueLevel = savedGreenBlueLevel
    }

    private func saveGreenSettings() {
        savedGreenBrightness = brightness
        savedGreenRedLevel = redLevel
        savedGreenGreenLevel = greenLevel
        savedGreenBlueLevel = blueLevel
    }

    private func restoreBlueSettings() {
        brightness = savedBlueBrightness
        redLevel = savedBlueRedLevel
        greenLevel = savedBlueGreenLevel
        blueLevel = savedBlueBlueLevel
    }

    private func saveBlueSettings() {
        savedBlueBrightness = brightness
        savedBlueRedLevel = redLevel
        savedBlueGreenLevel = greenLevel
        savedBlueBlueLevel = blueLevel
    }

    private func saveCurrentPresetSettings() {
        switch preset {
        case .red:
            saveRedSettings()
        case .green:
            saveGreenSettings()
        case .blue:
            saveBlueSettings()
        case .custom:
            saveCustomSettings()
        }
    }

    private func startDaemon() {
        performRustAction("Started background daemon") {
            startDisplayDaemon(
                brightness: UInt8(brightness),
                red: UInt8(redLevel),
                green: UInt8(greenLevel),
                blue: UInt8(blueLevel)
            )
        }
    }

    private func resetButtonTapped() {
        isApplyingPreset = true
        switch preset {
        case .red:
            brightness = 100
            redLevel = 100
            greenLevel = 0
            blueLevel = 0
            saveRedSettings()
        case .green:
            brightness = 100
            redLevel = 0
            greenLevel = 100
            blueLevel = 0
            saveGreenSettings()
        case .blue:
            brightness = 100
            redLevel = 0
            greenLevel = 0
            blueLevel = 100
            saveBlueSettings()
        case .custom:
            brightness = 100
            redLevel = 100
            greenLevel = 100
            blueLevel = 100
            saveCustomSettings()
        }

        performRustAction("Restored display defaults") {
            RustyLib.resetDisplay()
        }

        applyCurrentSettings()
        DispatchQueue.main.async {
            isApplyingPreset = false
        }
    }

    private func performRustAction(_ successMessage: String, action: () -> Bool) {
        if action() {
            statusMessage = successMessage
        } else {
            statusMessage = "Operation failed"
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

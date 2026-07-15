import RustyLib
import SwiftUI

private enum ChannelPreset: String, CaseIterable, Identifiable {
    case full = "Full"
    case red = "Red"
    case green = "Green"
    case blue = "Blue"
    case custom = "Custom"

    var id: String { rawValue }
}

struct ContentView: View {
    @State private var brightness: Double = 100
    @State private var redLevel: Double = 100
    @State private var greenLevel: Double = 100
    @State private var blueLevel: Double = 100
    @State private var preset: ChannelPreset = .custom
    @State private var statusMessage = "Ready"

    var body: some View {
        NavigationStack {
            Form {
                Section("Brightness") {
                    Slider(value: $brightness, in: 1...100, step: 1)
                    Text("\(Int(brightness))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Channel preset") {
                    Picker("Preset", selection: $preset) {
                        ForEach(ChannelPreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Custom RGB levels") {
                    Slider(value: $redLevel, in: 0...100, step: 1)
                    Text("Red \(Int(redLevel))%")

                    Slider(value: $greenLevel, in: 0...100, step: 1)
                    Text("Green \(Int(greenLevel))%")

                    Slider(value: $blueLevel, in: 0...100, step: 1)
                    Text("Blue \(Int(blueLevel))%")
                }

                Section("Actions") {
                    HStack {
                        Button("Apply") {
                            applyCurrentSettings()
                        }

                        Button("Start") {
                            startDaemon()
                        }

                        Button("Stop") {
                            stopDaemon()
                        }

                        Button("Reset") {
                            resetButtonTapped()
                        }
                    }
                }

                Section("Status") {
                    Text(statusMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Red Level")
        }
        .onAppear() {
            startDaemon()
        }
        .onChange(of: brightness) { _, brightness in
            applyCurrentSettings()
        }
        .onChange(of: redLevel){ _, redLevel in
            applyCurrentSettings()
        }
        .onChange(of: greenLevel){ _, greenLevel in
            applyCurrentSettings()
        }
        .onChange(of: blueLevel){ _, blueLevel in
            applyCurrentSettings()
        }
        .onChange(of: preset) { _, newPreset in
            applyPreset(newPreset)
        }
    }

    private func applyPreset(_ preset: ChannelPreset) {
        switch preset {
        case .full:
            redLevel = 100
            greenLevel = 100
            blueLevel = 100
        case .red:
            redLevel = 100
            greenLevel = 0
            blueLevel = 0
        case .green:
            redLevel = 0
            greenLevel = 100
            blueLevel = 0
        case .blue:
            redLevel = 0
            greenLevel = 0
            blueLevel = 100
        case .custom:
            break
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

    private func stopDaemon() {
        performRustAction("Stopped background daemon") {
            stopDisplayDaemon()
        }
    }

    private func resetButtonTapped() {
        brightness = 100
        preset = .full
        applyPreset(.full)

        performRustAction("Restored display defaults") {
            RustyLib.resetDisplay()
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

#Preview {
    ContentView()
}

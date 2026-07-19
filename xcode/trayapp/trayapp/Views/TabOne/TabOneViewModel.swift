//
//  TabOneViewModel.swift
//  trayapp
//
//  Created by git on 7/18/26.
//

import Foundation
import RustyLib

@MainActor
final class TabOneViewModel: ObservableObject {
    @Published var brightness: Double = 100
    @Published var redLevel: Double = 100
    @Published var greenLevel: Double = 100
    @Published var blueLevel: Double = 100
    @Published var statusMessage: String = "Ready"
    @Published private(set) var isApplyingPreset = false

    func startDaemon() {
        performRustAction("Started background daemon") {
            startDisplayDaemon(
                brightness: UInt8(brightness),
                red: UInt8(redLevel),
                green: UInt8(greenLevel),
                blue: UInt8(blueLevel)
            )
        }
    }

    func applyCurrentSettings() {
        performRustAction("Applied display settings") {
            applyDisplay(
                brightness: UInt8(brightness),
                red: UInt8(redLevel),
                green: UInt8(greenLevel),
                blue: UInt8(blueLevel)
            )
        }
    }

    func applyFullPreset() {
        applyPreset(brightness: 100, red: 100, green: 100, blue: 100, message: "Applied full preset")
    }

    func applyRedPreset() {
        applyPreset(brightness: 100, red: 100, green: 0, blue: 0, message: "Applied red preset")
    }

    func applyGreenPreset() {
        applyPreset(brightness: 100, red: 0, green: 100, blue: 0, message: "Applied green preset")
    }

    func applyBluePreset() {
        applyPreset(brightness: 100, red: 0, green: 0, blue: 100, message: "Applied blue preset")
    }

    func resetDisplay() {
        isApplyingPreset = true
        defer { isApplyingPreset = false }

        brightness = 100
        redLevel = 100
        greenLevel = 100
        blueLevel = 100

        performRustAction("Restored display defaults") {
            RustyLib.resetDisplay()
        }

        applyCurrentSettings()
        statusMessage = "Restored display defaults"
    }

    private func applyPreset(brightness: Double, red: Double, green: Double, blue: Double, message: String) {
        isApplyingPreset = true
        defer { isApplyingPreset = false }

        self.brightness = brightness
        self.redLevel = red
        self.greenLevel = green
        self.blueLevel = blue
        performRustAction(message) {
            applyDisplay(
                brightness: UInt8(self.brightness),
                red: UInt8(self.redLevel),
                green: UInt8(self.greenLevel),
                blue: UInt8(self.blueLevel)
            )
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

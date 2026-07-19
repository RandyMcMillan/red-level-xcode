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
    private var pendingApplyTask: Task<Void, Never>?

    init() {
        let settings = SettingsManager.shared
        brightness = settings.displayBrightness
        redLevel = settings.displayRedLevel
        greenLevel = settings.displayGreenLevel
        blueLevel = settings.displayBlueLevel
    }

    func applyCurrentSettings() {
        cancelPendingApply()
        saveDisplaySettings()
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
        cancelPendingApply()
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
        cancelPendingApply()
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

    func scheduleCurrentSettingsApply() {
        cancelPendingApply()
        pendingApplyTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled, let self else { return }
            await self.applyCurrentSettings()
        }
    }

    private func cancelPendingApply() {
        pendingApplyTask?.cancel()
        pendingApplyTask = nil
    }

    private func saveDisplaySettings() {
        let settings = SettingsManager.shared
        settings.displayBrightness = brightness
        settings.displayRedLevel = redLevel
        settings.displayGreenLevel = greenLevel
        settings.displayBlueLevel = blueLevel
    }

    private func performRustAction(_ successMessage: String, action: () -> Bool) {
        if action() {
            statusMessage = successMessage
        } else {
            statusMessage = "Operation failed"
        }
    }
}

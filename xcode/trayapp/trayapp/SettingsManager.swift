//
//  SettingsManager.swift
//  trayapp
//
//  Created by git on 7/18/26
//

import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    private let defaults = UserDefaults.standard

    // Keys
    private let appLoggingEnabledKey = "___PRODUCT_BUNDLE_IDENTIFIER___.settings.appLoggingEnabled"
    private let usernameKey            = "___PRODUCT_BUNDLE_IDENTIFIER___.settings.username"
    private let displayBrightnessKey   = "___PRODUCT_BUNDLE_IDENTIFIER___.display.brightness"
    private let displayRedLevelKey     = "___PRODUCT_BUNDLE_IDENTIFIER___.display.redLevel"
    private let displayGreenLevelKey   = "___PRODUCT_BUNDLE_IDENTIFIER___.display.greenLevel"
    private let displayBlueLevelKey    = "___PRODUCT_BUNDLE_IDENTIFIER___.display.blueLevel"

    // MARK: – App Logging
    var appLoggingEnabled: Bool {
        get { defaults.bool(forKey: appLoggingEnabledKey) }
        set { defaults.set(newValue, forKey: appLoggingEnabledKey) }
    }

    // MARK: – Username
    var username: String {
        get { defaults.string(forKey: usernameKey) ?? "" }
        set { defaults.set(newValue, forKey: usernameKey) }
    }

    // MARK: – Display
    var displayBrightness: Double {
        get { defaults.object(forKey: displayBrightnessKey) as? Double ?? 100 }
        set { defaults.set(newValue, forKey: displayBrightnessKey) }
    }

    var displayRedLevel: Double {
        get { defaults.object(forKey: displayRedLevelKey) as? Double ?? 100 }
        set { defaults.set(newValue, forKey: displayRedLevelKey) }
    }

    var displayGreenLevel: Double {
        get { defaults.object(forKey: displayGreenLevelKey) as? Double ?? 100 }
        set { defaults.set(newValue, forKey: displayGreenLevelKey) }
    }

    var displayBlueLevel: Double {
        get { defaults.object(forKey: displayBlueLevelKey) as? Double ?? 100 }
        set { defaults.set(newValue, forKey: displayBlueLevelKey) }
    }
}

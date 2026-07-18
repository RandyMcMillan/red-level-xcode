//
//  SettingsTabViewModel.swift
//  trayapp
//
//  Created by git on 7/18/26.
//

import Foundation
import Combine

class SettingsTabViewModel: ObservableObject {
    @Published var appLoggingEnabled: Bool {
        didSet {
            SettingsManager.shared.appLoggingEnabled = appLoggingEnabled
        }
    }

    @Published var username: String {
        didSet {
            SettingsManager.shared.username = username
        }
    }

    init() {
        let settingsMgr = SettingsManager.shared
        self.appLoggingEnabled = settingsMgr.appLoggingEnabled
        self.username          = settingsMgr.username
    }
}

//
//  SettingsTabContent.swift
//  trayapp
//
//  Created by git on 7/18/26
//

import SwiftUI
/**

 ## Don't forget to add the `LaunchAtLogin` dependency:

 1. Click File → Add Packages…
 2. In the search box in the upper right, enter:
    https://github.com/sindresorhus/LaunchAtLogin-Modern
 3. Click Add Package
 4. Click Add Package, again

 */
import LaunchAtLogin

struct SettingsTabContent: View {
    @StateObject private var vm = SettingsTabViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 12) {
                LaunchAtLogin.Toggle()
                    .toggleStyle(.switch)
                    .help("Launch this app automatically when you log in")

                Toggle("Enable Logging", isOn: $vm.appLoggingEnabled)
                    .toggleStyle(.switch)
                    .help("Turn application logging on or off")

                TextField("Username", text: $vm.username)
                    .textFieldStyle(.roundedBorder)
                    .help("Enter and save your username")
            }
            .frame(maxWidth: 360, alignment: .leading)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
    }
}

#if DEBUG
struct SettingsTabContent_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTabContent()
    }
}
#endif

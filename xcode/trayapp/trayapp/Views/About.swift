//
//  About.swift
//  trayapp
//
//  Created by git on 7/18/26.
//

import SwiftUI
import AppKit

struct AboutTabContent: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 14) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("trayapp")
                            .font(.title2.weight(.semibold))
                        Text("Menu bar control for display presets and RGB levels.")
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("How to use")
                        .font(.headline)

                    Text("1. Open the trayapp menu bar popover.")
                    Text("2. Use Display to set brightness and RGB channels.")
                    Text("3. Use Settings to change login and logging preferences.")
                    Text("4. Use Info to read this help and quit the app.")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Keyboard shortcuts")
                        .font(.headline)

                    Text("Cmd-1: Display tab")
                    Text("Cmd-2: Settings tab")
                    Text("Cmd-3: Info tab")
                    Text("Cmd-I: About trayapp menu item")
                    Text("Cmd-Q: Quit trayapp")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Display controls")
                        .font(.headline)

                    Text("• Brightness adjusts overall intensity.")
                    Text("• Red, Green, and Blue sliders control the active channel mix.")
                    Text("• Presets save and restore common channel configurations.")
                    Text("• Reset restores the current preset to its default values.")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Settings")
                        .font(.headline)

                    Text("• Launch at Login starts trayapp automatically.")
                    Text("• Enable Logging toggles app logging.")
                    Text("• Username stores a simple user preference locally.")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Links")
                        .font(.headline)

                    Link("https://github.com/RandyMcMillan/red-level-xcode", destination: URL(string: "https://github.com/RandyMcMillan/red-level-xcode")!)
                    Link("https://github.com/RandyMcMillan", destination: URL(string: "https://github.com/RandyMcMillan")!)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Link("LICENSE", destination: URL(string: "https://raw.githubusercontent.com/RandyMcMillan/red-level-xcode/refs/heads/main/LICENSE")!)
                    }
                    .font(.body)

                    Spacer()

                    Button("Quit trayapp") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }
}

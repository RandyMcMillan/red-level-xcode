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
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 48, height: 48)
                .cornerRadius(12)

            Text("trayapp")
                .font(.title2.weight(.semibold))

            Text("This tool helps you manage display settings from the menu bar.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)

            Divider()

            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("License: MIT")
                    Text("Author: Alexey Sedoykin")
                    Text("Contact: www.linkedin.com/in/sedoykin")
                }
                .font(.body)

                Spacer()

                Button("Exit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(20)
    }
}

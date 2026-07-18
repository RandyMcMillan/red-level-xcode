//
//  EntryPointApp.swift
//  trayapp
//
//  Created by git on 7/18/26
//

import SwiftUI
import AppKit
import Foundation

@main
struct EntryPointApp: App {
    @Environment(\.openWindow) var openWindow
    @StateObject private var appState = AppState.shared
    init() {
        ensureSavedStateDirectoryExists()
        AppStateFixer.repairSavedStateDirectory()
        Helpers.checkInternetConnection {
                print("Connected to WAN")
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
        } label: {
            MenuBarIcon(appState: appState)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarContentView: View {
    @State private var optionKeyPressed = false

    var body: some View {
        Group {
            if optionKeyPressed {
                //optional for showing by hold option key and clicking on app icon
                //InfoWindow()
            } else {
                MainWindow()
            }
        }
        .onAppear {
            optionKeyPressed = NSEvent.modifierFlags.contains(.option)
        }
    }
}

func ensureSavedStateDirectoryExists() {
    let fileManager = FileManager.default
    
    // Locate the user's Library directory (will automatically point inside the Sandbox container if sandboxed)
    guard let libraryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
        print("[-] Failed to locate Library directory.")
        return
    }
    
    // Reconstruct the exact path AppKit expects for state restoration
    if let bundleID = Bundle.main.bundleIdentifier {
        let savedStateDirURL = libraryURL
            .appendingPathComponent("Saved Application State")
            .appendingPathComponent("\(bundleID).savedState")
        
        // Check if it already exists; if not, create it defensively
        //if !fileManager.fileExists(atPath: savedStateDirURL.path) {
            do {
                try fileManager.createDirectory(at: savedStateDirURL, withIntermediateDirectories: true, attributes: nil)
                print("[+] Successfully pre-created savedState directory at: \(savedStateDirURL.path)")
            } catch {
                print("[-] Failed to create savedState directory: \(error.localizedDescription)")
            }
        //}
    }
}

// Call this inside your AppDelegate or before NSApplicationMain()
// ensureSavedStateDirectoryExists()
 
public final class AppStateFixer {
    
    /// Ensures that the local AppKit state restoration architecture is initialized
    /// to prevent internal `_NSPersistentUI` file descriptor and stat errors.
    public static func repairSavedStateDirectory() {
        let fileManager = FileManager.default
        
        // Dynamically resolve the Sandboxed Library directory path
        guard let libraryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            print("[-] [AppStateFixer] Failed to resolve local library container sub-tree.")
            return
        }
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            print("[-] [AppStateFixer] Failed to extract valid bundle identifier string.")
            return
        }
        
        // Reconstruct the explicit restoration path context
        let savedStateDirectory = libraryURL
            .appendingPathComponent("Saved Application State", isDirectory: true)
            .appendingPathComponent("\(bundleIdentifier).savedState", isDirectory: true)
        
        let restoreCountPlistFile = savedStateDirectory.appendingPathComponent("restorecount.plist", isDirectory: false)
        
        do {
            // Ensure the directory layout exists
            if !fileManager.fileExists(atPath: savedStateDirectory.path) {
                try fileManager.createDirectory(at: savedStateDirectory, withIntermediateDirectories: true, attributes: nil)
                print("[+] [AppStateFixer] Created missing layout path: \(savedStateDirectory.path)")
            }
            
            // Explicitly verify or place a blank plist so stat() system calls succeed
            if !fileManager.fileExists(atPath: restoreCountPlistFile.path) {
                let emptyData = try PropertyListSerialization.data(fromPropertyList: [String: String](), format: .xml, options: 0)
                try emptyData.write(to: restoreCountPlistFile, options: .atomic)
                print("[+] [AppStateFixer] Initialized placeholder target: \(restoreCountPlistFile.path)")
            }
        } catch {
            print("[-] [AppStateFixer] Critical failure during filesystem adjustments: \(error.localizedDescription)")
        }
    }
}

// Invoke early during execution layout:
// AppStateFixer.repairSavedStateDirectory()


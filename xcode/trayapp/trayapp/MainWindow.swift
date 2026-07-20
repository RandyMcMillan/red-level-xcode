//
//  MainWindow.swift
//  trayapp
//
//  Created by git on 7/18/26
//

import SwiftUI
/**

 ## Don't forget to add the `ElegantTabs` dependency:

 1. Click File → Add Packages…
 2. In the search box in the upper right, enter:
    https://github.com/Krusty84/ElegantTabs
 3. Click Add Package
 4. Click Add Package, again

 */
import ElegantTabs

struct MainWindow: View {
    @ObservedObject private var appState = AppState.shared
    var body: some View {
        ElegantTabsView(selection: $appState.selectedTabIndex) {
            TabItem(title: "Display", icon: .system(name: "sun.max.fill")) {
                TabOneContent()
            }
            TabItem(title: "Settings", icon: .system(name: "gearshape.fill")) {
                SettingsTabContent()
            }
            TabItem(title: "Info", icon: .system(name: "info")) {
                AboutTabContent()
            }
        }
        .frame(minWidth: 0, idealWidth: 780, maxWidth: 880, minHeight: 0, idealHeight: 560, maxHeight: 720)
    }
}

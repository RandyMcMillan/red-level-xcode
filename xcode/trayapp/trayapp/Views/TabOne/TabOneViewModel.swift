//
//  ExampleViewModel.swift
//  trayapp
//
//  Created by git on 7/18/26.
//

import Foundation

class TabOneViewModel: ObservableObject {
    @Published var title: String = "Hello, SwiftUI!"

    func changeTitle() {
        title = "Title changed!"
    }
}

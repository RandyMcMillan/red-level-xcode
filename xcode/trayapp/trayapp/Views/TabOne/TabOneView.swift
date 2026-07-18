//
//  ExampleView.swift
//  trayapp
//
//  Created by git on 7/18/26.
//

import SwiftUI

struct TabOneContent: View {
    @StateObject private var viewModel = TabOneViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text(viewModel.title)
                .font(.title)
            Button("Change Title") {
                viewModel.changeTitle()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#if DEBUG
struct TabOneContent_Previews: PreviewProvider {
    static var previews: some View {
        TabOneContent()
    }
}
#endif

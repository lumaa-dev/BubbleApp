//Made by Lumaa

import SwiftUI

extension View {
    func listThreaded() -> some View {
        self
            .scrollContentBackground(.hidden)
            .tint(Color.white)
            .background(Color.appBackground)
            .listStyle(.inset)
    }
    func listRowThreaded() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowBackground(Color.appBackground)
    }
}

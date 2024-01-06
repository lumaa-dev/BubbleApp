//Made by Lumaa

import SwiftUI

extension View {
    func listThreaded(tint: Color = Color(uiColor: UIColor.label)) -> some View {
        self
            .scrollContentBackground(.hidden)
            .tint(tint)
            .background(Color.appBackground)
            .listStyle(.inset)
    }
    func listRowThreaded() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowBackground(Color.appBackground)
    }
}

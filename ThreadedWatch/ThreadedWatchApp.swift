//Made by Lumaa

import SwiftUI

@main
struct ThreadedWatch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelData()
        }
    }
}

extension View {
    func modelData() -> some View {
        self
            .modelContainer(for: LoggedAccount.self)
    }
}

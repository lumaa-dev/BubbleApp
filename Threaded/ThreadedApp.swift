//Made by Lumaa

import SwiftUI

@main
struct ThreadedApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color(uiColor: .label))
                .background(Color.appBackground)
                .onAppear {
                    HapticManager.prepareHaptics()
                }
        }
    }
}

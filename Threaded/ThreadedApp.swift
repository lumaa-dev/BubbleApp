//Made by Lumaa

import SwiftUI

@main
struct ThreadedApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(Color.appBackground)
                .onAppear {
                    HapticManager.prepareHaptics()
                }
        }
    }
}

extension AppInfo {
    static var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
}

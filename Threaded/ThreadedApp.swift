//Made by Lumaa

import SwiftUI
import TipKit

@main
struct ThreadedApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(Color.appBackground)
                .onAppear {
                    HapticManager.prepareHaptics()
                }
                .task {
                    Tips.showAllTipsForTesting()
                    
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
        }
    }
}

extension AppInfo {
    static var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
}

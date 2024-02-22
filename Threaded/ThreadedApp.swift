//Made by Lumaa

import SwiftUI
import TipKit
import RevenueCat

@main
struct ThreadedApp: App {
    init() {
        guard let plist = AppDelegate.readSecret() else { return }
        if let apiKey = plist["RevenueCat_public"], let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            #if DEBUG
            Purchases.logLevel = .debug
            #endif
            Purchases.configure(withAPIKey: apiKey, appUserID: deviceId)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(Color.appBackground)
                .onAppear {
                    HapticManager.prepareHaptics()
                }
                .task {
                    #if DEBUG
                    Tips.showAllTipsForTesting()
                    UserDefaults.standard.removeObject(forKey: "lastVersion")
                    #endif
                    
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
                .modelData()
        }
    }
}

extension AppInfo {
    static var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
}

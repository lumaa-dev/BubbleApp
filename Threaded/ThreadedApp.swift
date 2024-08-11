//Made by Lumaa

import SwiftUI
import TipKit
import RevenueCat

@main
struct ThreadedApp: App {
    init() {
        guard let plist = AppDelegate.readSecret() else { fatalError("Missing Secret.plist file") }

        if let apiKey = plist["RevenueCat_public"], let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            #if DEBUG
            Purchases.logLevel = .debug
            #endif
            if #available(iOS 18.0, *) {
                Purchases.configure(withAPIKey: apiKey, appUserID: deviceId)
            }
        }

        ThreadedShortcuts.updateAppShortcutParameters()
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

public extension View {
    @ViewBuilder
    func modelData() -> some View {
        self
            .modelContainer(for: [LoggedAccount.self, ModelFilter.self])
    }
}

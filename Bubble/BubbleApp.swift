//Made by Lumaa

import SwiftUI
import TipKit
import RevenueCat

@main
struct BubbleApp: App {
    init() {
        guard let plist = AppDelegate.readSecret() else { fatalError("Missing Secret.plist file") }

        if let apiKey = plist["RevenueCat_public"], let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            #if DEBUG
            Purchases.logLevel = .debug
            #endif
            Purchases.configure(withAPIKey: apiKey, appUserID: deviceId)
        }

        BubbleShortcuts.updateAppShortcutParameters() //might not work?
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(Color.appBackground)
                .onAppear {
                    HapticManager.prepareHaptics()
                }
                .task {
                    #if targetEnvironment(simulator)
                    Tips.showAllTipsForTesting()
                    UserDefaults.standard.set("ABC", forKey: "lastVersion")
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
            .modelContainer(for: [LoggedAccount.self, ModelFilter.self, StatusDraft.self])
    }
}

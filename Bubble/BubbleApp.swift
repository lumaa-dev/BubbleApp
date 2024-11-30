//Made by Lumaa

import SwiftUI
import TipKit
import RevenueCat

@main
struct BubbleApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    init() {
        BubbleShortcuts.updateAppShortcutParameters() //might not work?
        
        guard let plist = AppDelegate.readSecret() else { print("Missing Secret.plist file"); return }

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
                    AVManager.configureForVideoPlayback()
                    AVManager.duckOther = false
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

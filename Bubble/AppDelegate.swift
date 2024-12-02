//Made by Lumaa

import SwiftUI
import SwiftData
import UIKit
import RevenueCat
import UserNotifications

@Observable
public class AppDelegate: NSObject, UIWindowSceneDelegate, Sendable, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    public var window: UIWindow?
    public private(set) var windowWidth: CGFloat = UIScreen.main.bounds.size.width
    public private(set) var windowHeight: CGFloat = UIScreen.main.bounds.size.height
    public private(set) var secret: [String: String] = [:]
    
    public static var premium: Bool = false
    public static var tokenized: Bool = false

    public func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = windowScene.keyWindow
    }
    
    override public init() {
        super.init()

        if let plist = AppDelegate.readSecret(), let apiKey = plist["RevenueCat_public"], let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            #if DEBUG
            Purchases.logLevel = .debug
            #endif
            Purchases.configure(withAPIKey: apiKey, appUserID: deviceId)
        } else {
            print("Missing Secret.plist file")
        }

        AppNotification.requestAuthorization { success in
            guard !Self.tokenized else { return }
            Self.tokenized = true
            let ownedAccs: [LoggedAccount] = self.getAccounts()
            ownedAccs.forEach { acc in
                Task {
                    let tempCli: Client = .init(server: acc.app?.server ?? "mastodon.social", oauthToken: acc.token)
                    await AppNotification.sendToken(client: tempCli, oauth: acc.token)
                }
            }
        }
        #if !WIDGET
        if !UIApplication.shared.isRegisteredForRemoteNotifications {
            print("Registering REMOTE NOTIFICATION")
            
            Task {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } else {
            let token: String? = UserDefaults.standard.string(forKey: "deviceToken")
            print("ALREADY registered REMOTE NOTIFICATION \(token ?? "???")")
        }
        #endif

        if let path = Bundle.main.path(forResource: "Secret", ofType: "plist") {
            let url = URL(fileURLWithPath: path)
            let data = try! Data(contentsOf: url)
            if let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [String: String] {
                secret = plist
            }
        }
        
        AppDelegate.hasPlus { subscribed in
            print("User has \(!subscribed ? "no-" : "")access to Plus")
            Self.premium = subscribed
        }

        windowWidth = window?.bounds.size.width ?? UIScreen.main.bounds.size.width
        windowHeight = window?.bounds.size.height ?? UIScreen.main.bounds.size.height
        Self.observedSceneDelegate.insert(self)
        _ = Self.observer // just for activating the lazy static property
    }
    public static var deviceToken: String = "[X]"

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppDelegate.deviceToken = token
        UserDefaults.standard.setValue(token, forKey: "deviceToken")

        print("[TOKEN] Got deviceToken: \(token)")
        // send device token to server
    }

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        print("[TOKEN]: \(error)")
    }

    static func readSecret() -> [String: String]? {
        if let path = Bundle.main.path(forResource: "Secret", ofType: "plist") {
            let url = URL(fileURLWithPath: path)
            let data = try! Data(contentsOf: url)
            if let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [String: String] {
                return plist
            }
        }
        
        return nil
    }

    private func getAccounts() -> [LoggedAccount] {
        guard let modelContainer: ModelContainer = try? ModelContainer(for: LoggedAccount.self, configurations: ModelConfiguration(isStoredInMemoryOnly: false)) else { return [] }
        let modelContext = ModelContext(modelContainer)
        let loggedAccounts = try? modelContext.fetch(FetchDescriptor<LoggedAccount>())

        return loggedAccounts ?? []
    }

    /// This function uses the REAL customer info to access the premium state
    static func hasPlus(completionHandler: @escaping (Bool) -> Void) {
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            guard let error else {
                let hasPrem: Bool = hasActuallyPlus(customerInfo: customerInfo)
                completionHandler(hasPrem)
                return
            }
            fatalError(error.localizedDescription)
        }
    }
    
    /// This function returns a fake "true" value every time whatever the customer info is
//    static func hasPlus(completionHandler: @escaping (Bool) -> Void) {
//        self.premium = true
//        completionHandler(true)
//    }
    
    private static func hasActuallyPlus(customerInfo: CustomerInfo?) -> Bool {
        return customerInfo?
            .entitlements[PlusEntitlements._3months.getEntitlementId()]?.isActive == true || customerInfo?
            .entitlements[PlusEntitlements.monthly.getEntitlementId()]?.isActive == true || customerInfo?
            .entitlements[PlusEntitlements.yearly.getEntitlementId()]?.isActive == true
    }
    
    deinit {
        self.deinits()
    }

    private func deinits() {
        Task { @MainActor in
            Self.observedSceneDelegate.remove(self)
        }
    }

    private static var observedSceneDelegate: Set<AppDelegate> = []
    private static let observer = Task {
        while true {
            try? await Task.sleep(for: .seconds(0.1))
            for delegate in observedSceneDelegate {
                let newWidth = delegate.window?.bounds.size.width ?? UIScreen.main.bounds.size.width
                if delegate.windowWidth != newWidth {
                    delegate.windowWidth = newWidth
                }
                let newHeight = delegate.window?.bounds.size.height ?? UIScreen.main.bounds.size.height
                if delegate.windowHeight != newHeight {
                    delegate.windowHeight = newHeight
                }
                
            }
        }
    }
}

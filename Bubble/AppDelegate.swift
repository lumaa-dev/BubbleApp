//Made by Lumaa

import SwiftUI
import UIKit
import RevenueCat

@Observable
public class AppDelegate: NSObject, UIWindowSceneDelegate, Sendable, UIApplicationDelegate {
    public var window: UIWindow?
    public private(set) var windowWidth: CGFloat = UIScreen.main.bounds.size.width
    public private(set) var windowHeight: CGFloat = UIScreen.main.bounds.size.height
    public private(set) var secret: [String: String] = [:]
    
    public static var premium: Bool = false
    
    public func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = windowScene.keyWindow
    }
    
    override public init() {
        super.init()
        
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
    
    /// This function uses the REAL customer info to access the premium state
    static func hasPlus(completionHandler: @escaping (Bool) -> Void) {
        #if targetEnvironment(simulator)
        completionHandler(true)
        #else
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            guard let error else {
                let hasPrem: Bool = hasActuallyPlus(customerInfo: customerInfo)
                completionHandler(hasPrem)
                return
            }
            fatalError(error.localizedDescription)
        }
        #endif
    }
    
    /// This function returns a fake "true" value every time whatever the customer info is
//    static func hasPlus() -> Bool {
//        self.premium = true
//        return true
//    }
    
    private static func hasActuallyPlus(customerInfo: CustomerInfo?) -> Bool {
        return customerInfo?.entitlements[PlusEntitlements.lifetime.getEntitlementId()]?.isActive == true || customerInfo?.entitlements[PlusEntitlements.monthly.getEntitlementId()]?.isActive == true || customerInfo?.entitlements[PlusEntitlements.yearly.getEntitlementId()]?.isActive == true
    }
    
    deinit {
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

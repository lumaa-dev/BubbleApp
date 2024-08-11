//Made by Lumaa

import Foundation

public enum AppInfo {
    public static let scopes = "read write follow push"
    public static let scheme = "threadedapp://"
    public static let clientName = "ThreadedApp"
    public static let defaultServer = "mastodon.social"
    public static let website = "https://apps.lumaa.fr/app/threaded"
}

extension AppInfo {
    static var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
}

//Made by Lumaa

import Foundation
import SwiftUI

public enum AppInfo {
    public static let scopes = "read write follow push"
    public static let scheme = "bubbleapp://"
    public static let clientName = "BubbleApp"
    public static let defaultServer = "mastodon.social"
    public static let website = "https://apps.lumaa.fr/app/bubble"
}

extension AppInfo {
    static var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

    /// App's features
    public enum Feature {
        case drafts
        case analytics
        case contentFilter
        case downloadAttachment
        case moreAccounts
        case subClub
        case experimentalSettings
        case vip
//        case intelligent

        //TODO: Upgrade this
        public var details: ShopView.PremiumFeature {
            switch self {
                case .drafts:
                    return .init("shop.features.drafts", description: "shop.features.drafts.description", systemImage: "pencil.and.outline")
                case .analytics:
                    return .init("shop.features.analytics", description: "shop.features.analytics.description", systemImage: "chart.line.uptrend.xyaxis.circle")
                case .contentFilter:
                    return .init("shop.features.content-filter", description: "shop.features.content-filter.description", systemImage: "wand.and.stars")
                case .downloadAttachment:
                    return .init("shop.features.download-atchmnt", description: "shop.features.download-atchmnt.description", systemImage: "photo.badge.arrow.down")
                case .moreAccounts:
                    return .init("shop.features.more-accounts", description: "shop.features.more-accounts.description", systemImage: "person.fill.badge.plus")
                case .subClub:
                    return .init(LocalizedStringKey(String("sub.club")), description: "info.subclub.description", systemImage: "person.crop.square.filled.and.at.rectangle.fill")
                case .experimentalSettings:
                    return .init("shop.features.experimental", description: "shop.features.experimental.description", systemImage: "gearshape.fill")
                case .vip:
                    return .init("shop.features.vip", description: "shop.features.vip.description", systemImage: "crown")
//                case .intelligent:
//                    return .init("shop.features.intelligent", description: "shop.features.intelligent.description", systemImage: "brain.fill")
            }
        }
    }
}

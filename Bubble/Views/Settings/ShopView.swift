//Made by Lumaa

import SwiftUI
import StoreKit
import RevenueCat

public struct ShopView: View {
    @Environment(AppDelegate.self) private var delegate: AppDelegate
    @Environment(\.openURL) private var openURL: OpenURLAction
    @Environment(\.dismiss) private var dismiss: DismissAction

    @State private var showSub: Bool = false
    @State private var purchaseError: Bool = false
    @State private var hasSub: Bool = false

    private var canPay: Bool {
        #if targetEnvironment(simulator) || !DEBUG
        return true
        #else
        return false
        #endif
    }

    public var body: some View {
        VStack {
            Image("HeroPlus")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(.vertical)

            if canPay {
                features
                    .padding(.bottom)
            } else {
                Spacer()

                ComingSoonView()
            }

            Spacer()

            if !self.hasSub {
                VStack(spacing: 20) {
                    Button {
                        showSub.toggle()
                    } label: {
                        Text("shop.bubble-plus.subscription")
                    }
                    .buttonStyle(LargeButton(filled: true, disabled: !canPay))
                    .overlay(alignment: .topTrailing) {
                        Text("shop.best")
                            .foregroundStyle(Color.white)
                            .font(.title2.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.1)
                            .padding(4.5)
                            .background(Capsule().fill(Color.red))
                            .offset(x: 20.0, y: -25.0)
                            .rotationEffect(.degrees(25.0))
                    }
                    .disabled(!canPay)

                    Button {
//                      showLifetime.toggle()
                        purchase(entitlement: .lifetime)
                    } label: {
                        Text("shop.bubble-plus.lifetime")
                    }
                    .buttonStyle(LargeButton(filled: false, disabled: !canPay))
                    .disabled(!canPay)

                    Button {
                        dismiss()
                    } label: {
                        Text("shop.bubble-plus.dismiss")
                    }
                    .buttonStyle(.borderless)
                    .padding(.top, 50)
                }
                .padding(.vertical)
            } else {
                VStack {
                    Button {
                        Task {
#if !targetEnvironment(simulator)
                            if let windowScene = self.delegate.window?.windowScene {
                                print("accessing subs natively")
                                try? await AppStore.showManageSubscriptions(in: windowScene)
                            } else {
                                print("accessing subs via deeplink")
                                openURL(URL(string: "itms-apps://apps.apple.com/account/subscriptions")!)
                            }
#else
                            print("ACCESS SUBS but Simulator can't")
#endif
                        }
                    } label: {
                        VStack {
                            Text("shop.bubble-plus.owning")
                                .font(.title2.bold())
                                .foregroundStyle(Color(uiColor: UIColor.label))

                            Text("shop.bubble-plus.manage")
                                .font(.callout)
                                .foregroundStyle(Color.blue)
                        }
                        .padding(.vertical)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("shop.bubble-plus.dismiss")
                    }
                    .buttonStyle(.borderless)
                    .padding(.top, 50)
                }
            }
        }
        .task {
            AppDelegate.hasPlus { subscribed in
                self.hasSub = subscribed
            }
        }
        .frame(width: delegate.windowWidth)
        .background(Color.appBackground)
        .navigationTitle(Text(String("Bubble+")))
        .sheet(isPresented: $showSub) {
            ShopView.SubView()
        }
    }
    
    var features: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 25) {
                Text("shop.features")
                    .font(.title.bold())
                    .scrollTransition { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0)
                            .blur(radius: phase.isIdentity ? 0 : 5)
                            .offset(y: phase.isIdentity ? 0 : -15)
                    }
                
                feature(.drafts)

//                feature(.analytics)

                feature(.contentFilter)

                feature(.downloadAttachment)

                feature(.moreAccounts)

                feature(.experimentalSettings)

                feature(.vip)
            }
            .frame(width: delegate.windowWidth)
        }
        .scrollIndicatorsFlash(onAppear: true)
        .scrollClipDisabled()
    }
    
    @ViewBuilder
    private func feature(_ title: LocalizedStringKey, description: LocalizedStringKey = LocalizedStringKey(String("")), systemImage: String) -> some View {
        HStack(alignment: .center) {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                Text(description)
                    .font(.callout)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.leading, 20)
        .frame(width: delegate.windowWidth - 30)
        .padding(.vertical)
        .background(Color.gray.opacity(0.2))
        .clipShape(.capsule)
        .scrollTransition { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0)
                .scaleEffect(x: phase.isIdentity ? 1 : 0.5, y: phase.isIdentity ? 1 : 0.75, anchor: .center)
                .blur(radius: phase.isIdentity ? 0 : 10)
                .offset(y: phase.isIdentity ? 0 : 10)
        }
    }

    @ViewBuilder
    private func feature(_ feature: ShopView.Feature) -> some View {
        HStack(alignment: .center) {
            Image(systemName: feature.details.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)

            VStack(alignment: .leading) {
                Text(feature.details.title)
                    .bold()
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                Text(feature.details.description)
                    .font(.callout)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(.leading, 20)
        .frame(width: delegate.windowWidth - 30)
        .padding(.vertical)
        .background(Color.gray.opacity(0.2))
        .clipShape(.capsule)
        .scrollTransition { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0)
                .scaleEffect(x: phase.isIdentity ? 1 : 0.5, y: phase.isIdentity ? 1 : 0.75, anchor: .center)
                .blur(radius: phase.isIdentity ? 0 : 10)
                .offset(y: phase.isIdentity ? 0 : 10)
        }
    }
}

// MARK: - Subscription View
extension ShopView {
    struct SubView: View {
        @State private var selectedPlan: PlusPlan = .monthly
        
        var body: some View {
            NavigationStack {
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    VStack {
                        header
                            .frame(height: 300)
                        
                        Spacer()
                        
                        Button {
                            guard selectedPlan != .monthly else { return }
                            withAnimation(.spring.speed(2.0)) {
                                selectedPlan = .monthly
                            }
                        } label: {
                            planSelector(.monthly, isSelected: selectedPlan == PlusPlan.monthly)
                        }
                        .buttonStyle(.plain)

                        
                        Button {
                            guard selectedPlan != .yearly else { return }
                            withAnimation(.spring.speed(2.0)) {
                                selectedPlan = .yearly
                            }
                        } label: {
                            planSelector(.yearly, isSelected: selectedPlan == PlusPlan.yearly)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                        
                        Button {
                            purchase(entitlement: selectedPlan.getEntitlement())
                        } label: {
                            Text("shop.bubble-plus.subscribe")
                        }
                        .buttonStyle(LargeButton(filled: true))
                    }
                }
            }
            .environment(\.colorScheme, ColorScheme.dark)
        }
        
        var header: some View {
            VStack {
                Spacer()
                
                Image("HeroPlus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                
                Spacer()
                
                Text(String("Bubble+")) // Force the name as untranslatable
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("shop.bubble-plus.subscription.description")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
        
        var tos: some View {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                Text("tos.description")
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal)
            }
            .environment(\.colorScheme, ColorScheme.dark)
        }
        
        @ViewBuilder
        private func planSelector(_ plan: PlusPlan, isSelected: Bool = false) -> some View {
            VStack(alignment: .leading) {
                Text(plan.getTitle())
                    .font(.headline.bold())
                    .multilineTextAlignment(.leading)
                
                Text(plan.getPrice())
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 30)
            .frame(width: 350)
            .background(Color.gray.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.green, lineWidth: 1.5)
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(uiColor: UIColor.label).opacity(0.35), lineWidth: 1.5)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.green)
                        .font(.title)
                }
            }
        }
        
        private enum PlusPlan {
            case monthly
            case yearly
            
            func getTitle() -> String {
                switch (self) {
                    case .monthly:
                        return String(localized: "shop.bubble-plus.monthly")
                    case .yearly:
                        return String(localized: "shop.bubble-plus.yearly")
                }
            }
            
            func getPrice() -> String {
                switch (self) {
                    case .monthly:
                        return String(localized: "shop.bubble-plus.monthly.price")
                    case .yearly:
                        return String(localized: "shop.bubble-plus.yearly.price")
                }
            }
            
            func getEntitlement() -> PlusEntitlements {
                switch (self) {
                    case .monthly:
                        return .monthly
                    case .yearly:
                        return .yearly
                }
            }
        }
    }
}

// MARK: - Feature list
extension ShopView {
    public enum Feature {
        case drafts
        case analytics
        case contentFilter
        case downloadAttachment
        case moreAccounts
        case experimentalSettings
        case vip

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
                case .experimentalSettings:
                    return .init("shop.features.experimental", description: "shop.features.experimental.description", systemImage: "gearshape.fill")
                case .vip:
                    return .init("shop.features.vip", description: "shop.features.vip.description", systemImage: "crown")
            }
        }
    }

    public struct PremiumFeature {
        let title: LocalizedStringKey
        let description: LocalizedStringKey
        let systemImage: String

        init(_ title: LocalizedStringKey, description: LocalizedStringKey, systemImage: String) {
            self.title = title
            self.description = description
            self.systemImage = systemImage
        }
    }
}

#Preview {
    ShopView()
        .environment(AppDelegate())
//        .environment(\.locale, Locale(identifier: "en-us"))
}

// MARK: - Entitlements
enum PlusEntitlements: String {
    case monthly
    case yearly
    case lifetime
    
    func toPackage(offerings: Offerings?) -> Package? {
        if let offs = offerings {
            switch (self) {
                case .monthly:
                    return offs.current?.monthly
                case .yearly:
                    return offs.current?.annual
                case .lifetime:
                    return offs.current?.lifetime
            }
        } else {
            return nil
        }
    }
    
    func getEntitlementId() -> String {
        switch (self) {
            case .lifetime:
                return "thrd_30$_life"
            case .monthly:
                return "thrd_2$_1mth_1mth0"
            case .yearly:
                return "thrd_20$_1y_1mth0"
        }
    }
}

private func hasActuallyPlus(customerInfo: CustomerInfo?) -> Bool {
    return customerInfo?.entitlements[PlusEntitlements.lifetime.getEntitlementId()]?.isActive == true || customerInfo?.entitlements[PlusEntitlements.monthly.getEntitlementId()]?.isActive == true || customerInfo?.entitlements[PlusEntitlements.yearly.getEntitlementId()]?.isActive == true
}

private func purchase(entitlement: PlusEntitlements) {
    Purchases.shared.getOfferings { (offerings, error) in
        if let product = entitlement.toPackage(offerings: offerings) {
            Purchases.shared.purchase(package: product) { (transaction, customerInfo, error, userCancelled) in
                if hasActuallyPlus(customerInfo: customerInfo) {
                    print("BOUGHT PLUS")
                    AppDelegate.premium = true
                }
            }
        }
        if let e = error {
            print(e)
        }
    }
}

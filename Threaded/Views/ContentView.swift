//Made by Lumaa

import SwiftUI

///
struct ContentView: View {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    @State private var preferences: UserPreferences = .defaultPreferences
    @StateObject private var uniNavigator = UniversalNavigator()
    @StateObject private var accountManager: AccountManager = AccountManager.shared
    
    var body: some View {
        ZStack {
            TabView(selection: $uniNavigator.selectedTab, content: {
                if accountManager.getAccount() != nil {
                    TimelineView(timelineModel: FetchTimeline(client: accountManager.forceClient()))
                        .background(Color.appBackground)
                        .tag(TabDestination.timeline)
                    
                    DiscoveryView()
                        .background(Color.appBackground)
                        .tag(TabDestination.search)
                    
                    NotificationsView()
                        .background(Color.appBackground)
                        .tag(TabDestination.activity)
                    
                    AccountView(account: accountManager.forceAccount())
                        .background(Color.appBackground)
                        .tag(TabDestination.profile)
                } else {
                    ZStack {
                        Color.appBackground
                            .ignoresSafeArea()
                    }
                }
            })
        }
        .overlay(alignment: .bottom) {
            if uniNavigator.showTabbar {
                TabsView(selectedTab: $uniNavigator.selectedTab) {
                    uniNavigator.presentedSheet = .post(content: "", replyId: nil, editId: nil)
                }
                .offset(y: uniNavigator.showTabbar ? 0 : -20)
                .zIndex(10)
            }
        }
        .withSheets(sheetDestination: $uniNavigator.presentedSheet)
        .withCovers(sheetDestination: $uniNavigator.presentedCover)
        .environment(uniNavigator)
        .environment(accountManager)
        .environment(appDelegate)
        .environmentObject(preferences)
        .onAppear {
            do {
                preferences = try UserPreferences.loadAsCurrent() ?? .defaultPreferences
            } catch {
                print(error)
            }
            
            if accountManager.getClient() == nil {
                Task {
                    await recognizeAccount()
                }
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            // Open internal URL.
            guard preferences.browserType == .inApp else { return .systemAction }
            uniNavigator.presentedSheet = .safari(url: url)
            return OpenURLAction.Result.handled
        })
        .onOpenURL(perform: { url in
            guard preferences.browserType == .inApp else { return }
            uniNavigator.presentedSheet = .safari(url: url)
        })
    }
    
    func recognizeAccount() async {
        let appAccount: AppAccount? = AppAccount.loadAsCurrent()
        if appAccount == nil {
            uniNavigator.presentedCover = .welcome
        } else {
            accountManager.setClient(.init(server: appAccount!.server, oauthToken: appAccount!.oauthToken))
            
            // Check if token is still working
            let fetched: Account? = await accountManager.fetchAccount()
            if fetched == nil {
                accountManager.clear()
                appAccount!.clear()
                uniNavigator.presentedCover = .welcome
            }
        }
    }
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.stackedLayoutAppearance.normal.iconColor = .white
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.accentColor)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(Color.accentColor)]
        
        UITabBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor.label
    }
}

#Preview {
    ContentView()
}

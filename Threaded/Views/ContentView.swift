//Made by Lumaa

import SwiftUI

struct ContentView: View {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    @State private var preferences: UserPreferences = .defaultPreferences
    @State private var navigator = Navigator()
    @State private var sheet: SheetDestination?
    @State private var accountManager: AccountManager = AccountManager()
    
    var body: some View {
        TabView(selection: $navigator.selectedTab, content: {
            ZStack {
                if accountManager.getClient() != nil {
                    TimelineView(navigator: navigator, timelineModel: FetchTimeline(client: accountManager.forceClient()))
                        .background(Color.appBackground)
                        .safeAreaPadding()
                } else {
                    ZStack {
                        Color.appBackground
                            .ignoresSafeArea()
                    }
                }
            }
            .background(Color.appBackground)
            .tag(TabDestination.timeline)
            
            Text(String("Search"))
                .background(Color.appBackground)
                .tag(TabDestination.search)
            
            //TODO: Messaging UI in Activity tab
            NotificationsView()
                .background(Color.appBackground)
                .tag(TabDestination.activity)
            
            ZStack {
                if accountManager.getAccount() != nil {
                    AccountView(isCurrent: true, account: accountManager.forceAccount())
                        .environment(navigator)
                        .background(Color.appBackground)
                } else {
                    ZStack {
                        Color.appBackground
                            .ignoresSafeArea()
                    }
                }
            }
            .background(Color.appBackground)
            .tag(TabDestination.profile)
            
        })
        .overlay(alignment: .bottom) {
            TabsView(navigator: navigator)
                .safeAreaPadding(.vertical)
                .zIndex(10)
        }
        .withCovers(sheetDestination: $sheet)
        .withSheets(sheetDestination: $navigator.presentedSheet)
        .environment(accountManager)
        .environment(navigator)
        .environment(appDelegate)
        .environment(preferences)
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
        .task {
            await recognizeAccount()
        }
        .environment(\.openURL, OpenURLAction { url in
            // Open internal URL.
            guard preferences.browserType == .inApp else { return .systemAction }
            navigator.presentedSheet = .safari(url: url)
            return OpenURLAction.Result.handled
        })
        .onOpenURL(perform: { url in
            guard preferences.browserType == .inApp else { return }
            navigator.presentedSheet = .safari(url: url)
        })
    }
    
    func recognizeAccount() async {
        let acc = try? AppAccount.loadAsCurrent()
        if acc == nil {
            sheet = .welcome
        } else {
            Task {
                accountManager.setClient(.init(server: acc!.server, oauthToken: acc!.oauthToken))
                
                // check if token is still working
                let fetched: Account? = await accountManager.fetchAccount()
                if fetched == nil {
                    accountManager.clear()
                    AppAccount.clear()
                    sheet = .welcome
                }
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

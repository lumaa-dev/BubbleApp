//Made by Lumaa

import SwiftUI

///
struct ContentView: View {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    @State private var preferences: UserPreferences = .defaultPreferences
    @State private var navigator: Navigator = .shared
    @StateObject private var accountManager: AccountManager = AccountManager.shared

    var body: some View {
        tabView
        .withSheets(sheetDestination: $navigator.presentedSheet)
        .withCovers(sheetDestination: $navigator.presentedCover)
        .environment(accountManager)
        .environment(appDelegate)
        .environmentObject(preferences)
        .onAppear {
            showNew()
            
            do {
                //TODO: Like AccMan > .static
                preferences = try UserPreferences.loadAsCurrent()
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
            return self.openURL(url)
        })
        .onOpenURL(perform: { url in
            _ = openURL(url)
        })
    }

    @ViewBuilder
    private var tabView: some View {
        TabView(selection: $navigator.selectedTab) {
            ForEach(TabDestination.allCases, id: \.self) { tab in
                Tab(value: tab, role: tab == TabDestination.search ? .search : .none) {
                    NavigationStack(path: $navigator[tab]) {
                        rootView(tab)
                            .withAppRouter()
                    }
                } label: {
                    tab.label
                }
            }
        }
        .task {
            await self.recognizeAccount()
        }
    }

    @ViewBuilder
    private func rootView(_ tab: TabDestination) -> some View {
        if let client = accountManager.getClient(), let account = accountManager.getAccount() {
            switch tab {
                case .timeline:
                    TimelineView(timelineModel: FetchTimeline(client: client))
                case .search:
                    DiscoveryView()
                case .post:
                    PostingView(initialString: "")
                case .activity:
                    NotificationsView()
                case .profile:
                    ProfileView(account: account)
            }
        } else {
            ProgressView()
        }
    }

    private func openURL(_ url: URL) -> OpenURLAction.Result {
        return Navigator.shared.handle(url: url)
    }

    func recognizeAccount() async {
        let appAccount: AppAccount? = AppAccount.loadAsCurrent()
        if appAccount == nil {
            navigator.presentedCover = .welcome
        } else {
            let cli = Client(server: appAccount!.server, oauthToken: appAccount!.oauthToken)
            accountManager.setClient(cli)

            // Check if token is still working
            let fetched: Account? = await accountManager.fetchAccount()
            if fetched == nil {
                accountManager.clear()
                appAccount!.clear()
                navigator.presentedCover = .welcome
            }
        }
    }
    
    func showNew() {
        if let lastVersion = UserDefaults.standard.string(forKey: "lastVersion") {
            if lastVersion != AppInfo.appVersion {
                UserDefaults.standard.setValue(AppInfo.appVersion, forKey: "lastVersion")
                navigator.presentedSheet = .update
            }
        } else {
            UserDefaults.standard.setValue(AppInfo.appVersion, forKey: "lastVersion")
        }
    }
}

#Preview {
    ContentView()
}

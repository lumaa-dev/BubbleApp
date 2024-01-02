//Made by Lumaa

import SwiftUI

struct ContentView: View {
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
            
            Text(String("Activity"))
                .background(Color.appBackground)
                .tag(TabDestination.activity)
            
            AccountView(isCurrent: true, account: accountManager.getAccount() ?? .placeholder())
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
        .task {
            await recognizeAccount()
        }
    }
    
    func recognizeAccount() async {
        let acc = try? AppAccount.loadAsCurrent()
        if acc == nil {
            sheet = .welcome
        } else {
            Task {
                accountManager.setClient(.init(server: acc!.server, oauthToken: acc!.oauthToken))
                await accountManager.fetchAccount()
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

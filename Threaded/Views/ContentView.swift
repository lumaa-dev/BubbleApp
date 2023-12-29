//Made by Lumaa

import SwiftUI

struct ContentView: View {
    @State private var navigator = Navigator()
    @State private var sheet: SheetDestination?
    @State private var client: Client?
    @State private var currentAccount: Account?
    
    var body: some View {
        TabView(selection: $navigator.selectedTab, content: {
            ZStack {
                if client != nil {
                    TimelineView(timelineModel: FetchTimeline(client: self.client!))
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
            
            ProfileView(account: currentAccount ?? .placeholder())
                .background(Color.appBackground)
                .tag(TabDestination.profile)
        })
        .overlay(alignment: .bottom) {
            TabsView(navigator: navigator)
                .safeAreaPadding(.vertical)
                .zIndex(10)
        }
        .withCovers(sheetDestination: $sheet)
        .environment(navigator)
        .environment(client)
        .onAppear {
            let acc = try? AppAccount.loadAsCurrent()
            if acc == nil {
                sheet = .welcome
            } else {
                Task {
                    client = .init(server: acc!.server, oauthToken: acc!.oauthToken)
                    currentAccount = try? await client!.get(endpoint: Accounts.verifyCredentials)
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
    }
}

#Preview {
    ContentView()
}

//Made by Lumaa

import SwiftUI
import SwiftData

//TODO: Bring back "Privacy" with mutelist, blocklist and default visibility

struct SettingsView: View {
    @Environment(UniversalNavigator.self) private var uniNav: UniversalNavigator
    
    @Query private var loggedAccounts: [LoggedAccount]

    @StateObject var navigator: Navigator
    @State private var switched: Bool = false
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            List {
                if loggedAccounts.count > 0 {
                    Section {
                        ForEach(loggedAccounts) { logged in
                            if let app = logged.app {
                                SwitcherRow(app: app)
                                    .listRowThreaded()
                            }
                        }
                        if AppDelegate.premium || loggedAccounts.count < 3 {
                            Button {
                                uniNav.presentedSheet = .mastodonLogin(logged: $switched)
                            } label: {
                                Label("settings.account-switcher.add", systemImage: "person.crop.circle.badge.plus")
                                    .foregroundStyle(Color.blue)
                            }
                            .listRowThreaded()
                        }
                    }
                    .onChange(of: switched) { _, new in
                        if new == true {
                            // switched correctly
                            HapticManager.playHaptics(haptics: Haptic.success)
                            uniNav.selectedTab = .timeline
                            navigator.path = []
                        }
                    }
                } else {
                    Section {
                        //MARK: Remove in later update
                        HStack(alignment: .center) {
                            Spacer()
                            Text("settings.account-switcher.relog")
                                .foregroundStyle(Color.gray)
                                .multilineTextAlignment(.center)
                                .font(.caption)
                            Spacer()
                        }
                        .listRowThreaded()
                    }
                }
                
                Spacer()
                    .frame(height: 30)
                    .listRowThreaded()
                
                Section {
                    Button {
                        navigator.navigate(to: .about)
                    } label: {
                        Label("about", systemImage: "info.circle")
                    }
                    .listRowThreaded()
                    
                    Button {
                        navigator.presentedCover = .shop
                    } label: {
                        Label(String("Threaded+"), systemImage: "plus")
                    }
                    .listRowThreaded()
                    
                    Button {
                        navigator.navigate(to: .support)
                    } label: {
                        Label("setting.support", systemImage: "person.line.dotted.person")
                    }
                    .listRowThreaded()
                    
                    Button {
                        navigator.navigate(to: .appearence)
                    } label: {
                        Label("setting.appearence", systemImage: "rectangle.3.group")
                    }
                    .listRowThreaded()
                    
                    Button {
                        AppAccount.clear()
                        navigator.path = []
                        uniNav.selectedTab = .timeline
                        uniNav.presentedCover = .welcome
                    } label: {
                        Text("logout")
                            .foregroundStyle(.red)
                    }
                    .tint(Color.red)
                    .listRowThreaded()
                }
            }
            .environmentObject(navigator)
            .withAppRouter(navigator)
            .withCovers(sheetDestination: $navigator.presentedCover)
            .listThreaded()
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension SettingsView {
    struct SwitcherRow: View {
        @Environment(AccountManager.self) private var accountManager: AccountManager
        @Environment(UniversalNavigator.self) private var uniNav: UniversalNavigator
        @EnvironmentObject private var navigator: Navigator
        
        var app: AppAccount
        
        @State private var account: Account? = nil
        @State private var error: Bool = false
        
        private var currentAccount: Bool {
            return AccountManager.shared.forceClient().server == app.server
        }
        
        init(app: AppAccount) {
            self.app = app
        }
        
        var body: some View {
            ZStack {
                if let acc = account {
                    HStack {
                        ProfilePicture(url: acc.avatar, size: 64)
                        
                        VStack(alignment: .leading) {
                            Text(acc.displayName ?? "@\(acc.acct)")
                                .multilineTextAlignment(.leading)
                            
                            Text("@\(acc.acct)")
                                .multilineTextAlignment(.leading)
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                        }
                        
                        Spacer()
                        
                        if !currentAccount {
                            Button {
                                Task {
                                    let c: Client = Client(server: app.server, oauthToken: app.oauthToken)
                                    let am: AccountManager = .init(client: c)
                                    
                                    let fetched: Account? = await am.fetchAccount()
                                    if fetched == nil {
                                        am.clear()
                                        error = true
                                    } else {
                                        AccountManager.shared.setAccount(fetched!)
                                        AccountManager.shared.setClient(c)
                                        uniNav.selectedTab = .timeline
                                        navigator.path = []
                                    }
                                }
                            } label: {
                                Text("settings.account-switcher.log")
                            }
                            .buttonStyle(LargeButton(filled: true, height: 7.5, disabled: currentAccount))
                            .disabled(currentAccount)
                        } else {
                            Text("settings.account-switcher.current")
                                .foregroundStyle(Color.gray)
                                .font(.caption)
                                .padding(.horizontal)
                                .lineLimit(1)
                        }
                    }
                } else {
                    Circle()
                        .fill(error ? Color.red.opacity(0.45) : Color.gray.opacity(0.45))
                        .frame(width: 54, height: 54)
                    
                    VStack(alignment: .leading) {
                        Text(Account.placeholder().displayName ?? "@\(Account.placeholder().acct)")
                            .redacted(reason: .placeholder)
                            .multilineTextAlignment(.leading)
                        
                        Text("@\(Account.placeholder().acct)")
                            .redacted(reason: .placeholder)
                            .multilineTextAlignment(.leading)
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                    }
                    
                    Spacer()
                    
                    Button {
                        print(acct)
                    } label: {
                        Text("settings.account-switcher.log")
                            .redacted(reason: .placeholder)
                    }
                    .buttonStyle(LargeButton(filled: true, height: 7.5))
                }
            }
            .task {
                account = await findAccount(acct: app.accountName!)
            }
        }
        
        private func findAccount(acct: String) async -> Account? {
            guard let client = accountManager.getClient() else { return nil }
            do {
                try await Task.sleep(for: .milliseconds(250))
                let results: SearchResults = try await client.get(endpoint: Search.search(query: acct, type: "accounts", offset: nil, following: nil), forceVersion: .v2)
                return results.accounts.first
            } catch {
                print(error)
            }
            return nil
        }
    }
}

//Made by Lumaa

import SwiftUI
import SwiftData
import WatchConnectivity

struct SettingsView: View {
    @Environment(UniversalNavigator.self) private var uniNav: UniversalNavigator
    
    @Query private var loggedAccounts: [LoggedAccount]
    
    @EnvironmentObject private var navigator: Navigator
    @State private var switched: Bool = false
    
    var body: some View {
        List {
            if loggedAccounts.count > 0 {
                Section {
                    ForEach(loggedAccounts) { logged in
                        if let app = logged.app {
                            SwitcherRow(app: app, loggedAccount: logged)
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
                Text("settings.restart-app")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                    .listRowThreaded()
                
                Button {
                    navigator.navigate(to: .about)
                } label: {
                    Label("about", systemImage: "info.circle")
                }
                .listRowThreaded()
                
                Button {
                    navigator.navigate(to: .privacy)
                } label: {
                    Label("privacy", systemImage: "lock")
                }
                .listRowThreaded()
                
                Button {
                    navigator.presentedCover = .shop
                } label: {
                    Label {
                        Text(String("Threaded+"))
                    } icon: {
                        Image("HeroPlus")
                            .resizable()
                            .scaledToFit()
                    }
                }
                .listRowThreaded()
                
                Button {
                    navigator.navigate(to: .support)
                } label: {
                    Label("setting.support", systemImage: "person.crop.circle.badge.questionmark")
                }
                .listRowThreaded()
                
//                Button {
//                    navigator.navigate(to: .appearence)
//                } label: {
//                    Label("setting.appearence", systemImage: "rectangle.3.group")
//                }
//                .listRowThreaded()
                
                Button {
                    if loggedAccounts.count <= 1 {
                        AppAccount.clear()
                        navigator.path = []
                        uniNav.selectedTab = .timeline
                        uniNav.presentedCover = .welcome
                    } else {
                        Task {
                            if let app = loggedAccounts[0].app {
                                let c: Client = Client(server: app.server, oauthToken: app.oauthToken)
                                let am: AccountManager = .init(client: c)
                                
                                let fetched: Account? = await am.fetchAccount()
                                if fetched == nil {
                                    am.clear()
                                } else {
                                    AccountManager.shared.setAccount(fetched!)
                                    AccountManager.shared.setClient(c)
                                    
                                    navigator.path = []
                                    uniNav.selectedTab = .timeline
                                }
                            }
                        }
                    }
                } label: {
                    Text("logout")
                        .foregroundStyle(.red)
                }
                .tint(Color.red)
                .listRowThreaded()
            }
        }
        .withAppRouter(navigator)
        .withCovers(sheetDestination: $navigator.presentedCover)
        .listThreaded()
        .navigationTitle("settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension SettingsView {
    struct SwitcherRow: View {
        @Environment(\.modelContext) private var modelContext
        @Environment(AccountManager.self) private var accountManager: AccountManager
        @Environment(UniversalNavigator.self) private var uniNav: UniversalNavigator
        @EnvironmentObject private var navigator: Navigator
        
        var logged: LoggedAccount
        var app: AppAccount
        
        private let connectivity: SessionDelegator = .init()
        
        @State private var account: Account? = nil
        @State private var error: Bool = false
        
        private var currentAccount: Bool {
            let currentAccount = AccountManager.shared.forceAccount()
            let currentClient = AccountManager.shared.forceClient()
            
            let currentAcct = "\(currentAccount.acct)@\(currentClient.server)"
            return currentAcct == app.accountName ?? ""
        }
        
        init(app: AppAccount, loggedAccount: LoggedAccount) {
            self.app = app
            self.logged = loggedAccount
        }
        
        var body: some View {
            ZStack {
                if let acc = account {
                    HStack {
                        ProfilePicture(url: acc.avatar, size: 46)
                        
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
                                        
                                        navigator.path = []
                                        uniNav.selectedTab = .timeline
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
                    .contextMenu {
                        Button {
                            app.saveAsCurrent()
                        } label: {
                            Label("settings.account-switcher.default", systemImage: "person.crop.circle.dashed")
                        }
                        
                        if !currentAccount {
                            Button(role: .destructive) {
                                modelContext.delete(self.logged)
                            } label: {
                                Label("settings.account-switcher.remove", systemImage: "trash")
                            }
                        }
                        
                        Divider()
                        
                        if connectivity.isWorking {
                            Button {
                                // double check in case states change in between
                                if connectivity.isWorking {
                                    let message = GivenAccount(acct: app.accountName!, bearerToken: app.oauthToken?.accessToken ?? "")
                                    connectivity.session.sendMessageData(message.turnToMessage(), replyHandler: { data in
                                        let str = String(data: data, encoding: .utf8)
                                        print(str ?? "No data?")
                                        HapticManager.playHaptics(haptics: Haptic.success)
                                    })
                                } else {
                                    print("No Watch?")
                                }
                            } label: {
                                Label("settings.account-switcher.send-to-watch", systemImage: "applewatch.and.arrow.forward")
                            }
                        }
                    }
                } else {
                    Circle()
                        .fill(error ? Color.red.opacity(0.45) : Color.gray.opacity(0.45))
                        .frame(width: 36, height: 36)
                    
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
                
                connectivity.initialize()
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

//Made by Lumaa

import SwiftUI

struct AccountRow<Content : View>: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    
    var acct: String
    @ViewBuilder var text: Content
    
    @State private var account: Account? = nil
    
    var body: some View {
        HStack(spacing: 20) {
            if let acc = account {
                ProfilePicture(url: acc.avatar, size: 64)
                
                VStack(alignment: .leading) {
                    text
                    
                    Text(acc.displayName ?? "@\(acc.acct)")
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Button {
                    UniversalNavigator.static.presentedSheet = nil
                    Navigator.shared.navigate(to: .account(acc: acc))
                } label: {
                    Text("account.view")
                }
                .buttonStyle(LargeButton(filled: true, height: 7.5))
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.45))
                    .frame(width: 54, height: 54)
                
                VStack(alignment: .leading) {
                    text
                        .redacted(reason: .placeholder)
                    
                    Text(Account.placeholder().displayName ?? "@\(Account.placeholder().acct)")
                        .redacted(reason: .placeholder)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Button {
                    print(acct)
                } label: {
                    Text("account.view")
                        .redacted(reason: .placeholder)
                }
                .buttonStyle(LargeButton(filled: true, height: 7.5))
            }
        }
        .task {
            await findAccount()
        }
    }
    
    private func findAccount() async {
        guard let client = accountManager.getClient() else { return }
        do {
            try await Task.sleep(for: .milliseconds(250))
            let results: SearchResults = try await client.get(endpoint: Search.search(query: acct, type: "accounts", offset: nil, following: nil), forceVersion: .v2)
            account = results.accounts.first
//            let relationships: [Relationship] = try await client.get(endpoint: Accounts.relationships(ids: results.accounts.map(\.id)))
//            relationship = relationships.first
        } catch {
            print(error)
        }
    }
}

#Preview {
    List {
        AccountRow(acct: "@lumaa@techhub.social") {
            EmptyView()
        }
    }
    .environmentObject(Navigator())
    .environment(AccountManager.shared)
}

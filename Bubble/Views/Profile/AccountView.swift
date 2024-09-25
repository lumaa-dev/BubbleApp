//Made by Lumaa

import SwiftUI

struct AccountView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    
    @State private var navigator: Navigator = Navigator.shared
    @State public var account: Account
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            ProfileView(account: account, isCurrent: true)
                .withAppRouter(navigator)
                .onAppear {
                    if let acc = accountManager.getAccount() {
                        account = acc
                    } else {
                        account = .placeholder()
                    }
                }
        }
        .environmentObject(navigator)
    }
}

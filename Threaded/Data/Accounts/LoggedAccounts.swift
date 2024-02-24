//Made by Lumaa

import Foundation
import SwiftUI
import SwiftData

@Model
class LoggedAccount {
    let token: OauthToken
    let acct: String
    let app: AppAccount?
    
    init(token: OauthToken, acct: String) {
        self.token = token
        self.acct = acct
        self.app = nil
    }
    
    init(appAccount: AppAccount) {
        guard let token = appAccount.oauthToken, let acct = appAccount.accountName else { fatalError("Cannot convert AppAccount to LoggedAccount") }
        self.token = token
        self.acct = acct
        self.app = appAccount
    }
}

public extension View {
    @ViewBuilder
    func modelData() -> some View {
        self
            .modelContainer(for: LoggedAccount.self)
    }
}

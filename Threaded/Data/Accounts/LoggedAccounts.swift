//Made by Lumaa

import Foundation
import SwiftUI
import SwiftData

@Model
class LoggedAccounts {
    let appAccounts: [AppAccount]
    let currentAccount: AppAccount
    
    static let shared: LoggedAccounts = LoggedAccounts()
    
    init(appAccounts: [AppAccount] = [], current: AppAccount? = nil) {
        let curr: AppAccount = current ?? AppAccount.loadAsCurrent()!
        self.appAccounts = appAccounts.count < 1 ? [curr] : appAccounts
        self.currentAccount = curr
    }
}

public extension View {
    @ViewBuilder
    func modelData() -> some View {
        self
            .modelContainer(for: LoggedAccounts.self)
    }
}

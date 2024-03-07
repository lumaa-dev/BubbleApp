//Made by Lumaa

import SwiftUI
import SwiftData
import WidgetKit
import AppIntents

/// Widgets that require to select an account will use this `ConfigurationIntent`
struct AccountAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.follow-count"
    static var description = IntentDescription("widget.follow-count.description")

    @Parameter(title: "widget.select-account")
    var account: AccountEntity?
}

struct AccountEntity: AppEntity {
    let client: Client
    let id: String
    let username: String
    /// Bearer token
    let token: OauthToken
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "account"
    static var defaultQuery = AccountQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: "@\(username)")
    }
    
    init(acct: String, username: String, token: OauthToken) {
        self.client = Client(server: String(acct.split(separator: "@")[1]), version: .v2, oauthToken: token)
        self.id = acct
        self.username = username
        self.token = token
    }
    
    init(loggedAccount: LoggedAccount) {
        self.client = Client(server: String(loggedAccount.acct.split(separator: "@")[1]), version: .v2, oauthToken: loggedAccount.token)
        self.id = loggedAccount.acct
        self.username = String(loggedAccount.acct.split(separator: "@")[0])
        self.token = loggedAccount.token
    }
    
    func toUIImage() -> URL? {
        Task { [self] in
            if let account: String = try? await client.getString(endpoint: Accounts.verifyCredentials) {
                do {
                    if let serialized: [String : Any] = try JSONSerialization.jsonObject(with: account.data(using: String.Encoding.utf8) ?? Data()) as? [String : Any] {
                        let avatar: String = serialized["avatar"] as! String
                        return URL(string: avatar) ?? URL.placeholder
                    }
                } catch {
                    print("Error fetching image data: \(error)")
                }
            }
            return URL.placeholder
        }
        return URL.placeholder
    }
}


struct AccountQuery: EntityQuery {
    private static func getAccountsQuery() -> [LoggedAccount] {
        let query = Query<LoggedAccount, [LoggedAccount]>()
        let loggedAccounts: [LoggedAccount] = query.wrappedValue
        return loggedAccounts
    }
    
    private static func getAccounts() -> [LoggedAccount] {
        guard let modelContainer: ModelContainer = try? ModelContainer(for: LoggedAccount.self, configurations: ModelConfiguration(isStoredInMemoryOnly: false)) else { return [] }
        let modelContext = ModelContext(modelContainer)
        let loggedAccounts = try? modelContext.fetch(FetchDescriptor<LoggedAccount>())
        
        return loggedAccounts ?? []
    }
    
    func entities(for identifiers: [AccountEntity.ID]) async throws -> [AccountEntity] {
        let accountEntities: [AccountEntity] = Self.getAccounts().map({ return AccountEntity(loggedAccount: $0) })
        return accountEntities.filter({ identifiers.contains($0.id) })
    }
    
    func suggestedEntities() async throws -> [AccountEntity] {
        let accountEntities: [AccountEntity] = Self.getAccounts().map({ return AccountEntity(loggedAccount: $0) })
        return accountEntities
    }
    
    func defaultResult() async -> AccountEntity? {
        try? await suggestedEntities().first
    }
}

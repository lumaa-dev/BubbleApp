//Made by Lumaa

import SwiftUI
import SwiftData
import WidgetKit
import AppIntents

// MARK: - Shortcuts

struct BubbleShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] = [
        .init(
            intent: OpenComposerIntent(),
            phrases: [
                "Start a \(.applicationName) post",
                "Post on \(.applicationName)"
            ],
            shortTitle: "status.posting",
            systemImageName: "square.and.pencil"
        )
    ]
    static var shortcutTileColor: ShortcutTileColor = .lightBlue
}

// MARK: - Account Intents

/// Widgets that require to select only an account will use this `ConfigurationIntent`
struct AccountAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.follow-count"
    static var description = IntentDescription("widget.follow-count.description")
    
    @Parameter(title: "widget.select-account")
    var account: AccountEntity?
}

struct AccountGoalAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.follow-goal"
    static var description = IntentDescription("widget.follow-goal.description")
    
    @Parameter(title: "widget.select-account")
    var account: AccountEntity?
    
    @Parameter(title: "widget.set-goal", default: 1_000)
    var goal: Int
}

struct AccountEntity: AppEntity {
    let client: Client
    let id: String
    let username: String
    let server: String
    /// Bearer token
    let token: OauthToken
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "account"
    static var defaultQuery = AccountQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: "@\(username)")
    }
    
    init(acct: String, username: String, token: OauthToken) {
        self.server = String(acct.split(separator: "@")[1])
        self.client = Client(server: self.server, version: .v2, oauthToken: token)
        self.id = acct
        self.username = username
        self.token = token
    }
    
    init(loggedAccount: LoggedAccount) {
        self.server = loggedAccount.app?.server ?? ""
        self.client = Client(server: self.server, version: .v2, oauthToken: loggedAccount.token)
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

// MARK: - Post Intents

extension Visibility: AppEnum {
    public static var caseDisplayRepresentations: [Visibility : DisplayRepresentation] {
        [
            .pub : DisplayRepresentation(title: "status.posting.visibility.public"),
            .priv : DisplayRepresentation(title: "status.posting.visibility.private"),
            .unlisted : DisplayRepresentation(title: "status.posting.visibility.unlisted"),
            .direct : DisplayRepresentation(title: "status.posting.visibility.direct")
        ]

    }

    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "status.posting.visibility")
    }
}

struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.open.app"

    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = true

    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    func perform() async throws -> some IntentResult {
        UniversalNavigator.static.selectedTab = .timeline
        UniversalNavigator.static.presentedSheet = nil

        if UniversalNavigator.static.presentedCover != .welcome {
            UniversalNavigator.static.presentedCover = nil
        }

        return .result()
    }
}

struct OpenComposerIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.open.composer"
    static var description: IntentDescription? = IntentDescription("intent.open.composer.description")

    static var isDiscoverable: Bool = true
    static var openAppWhenRun: Bool = true

    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    func perform() async throws -> some IntentResult {
        UniversalNavigator.static.presentedSheet =
            .post(content: "", replyId: nil, editId: nil)
        return .result()
    }
}

struct PublishTextIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.publish.text"
    static var description: IntentDescription? = IntentDescription("intent.publish.text.description")

    static var isDiscoverable: Bool = true
    static var openAppWhenRun: Bool = false

    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    @Parameter(title: "account", requestDisambiguationDialog: IntentDialog("intent.publish.text.account-dialog"))
    var account: AccountEntity?

    @Parameter(title: "status.posting.placeholder", requestValueDialog: IntentDialog("intent.publish.text.content-dialog"))
    var content: String

    @Parameter(title: "status.posting.visibility", requestDisambiguationDialog: IntentDialog("intent.publish.any.visibility-dialog"))
    var visibility: Visibility

    static var parameterSummary: any ParameterSummary {
        Summary("intent.publish.text.summary-\(\.$content)") {
            \.$account
            \.$visibility
        }
    }

    func perform() async throws -> some IntentResult & ShowsSnippetView & ReturnsValue<String> {
        if let client = account?.client, !client.server.isEmpty {
            let data: StatusData = .init(
                status: self.content,
                visibility: self.visibility
            )

            // posting requires v1
            if let res = try? await client.post(endpoint: Statuses.postStatus(json: data), forceVersion: .v1), res.statusCode == 200 {
                return .result(
                    value: self.content,
                    view: Self.StatusSuccess(acc: account!, json: data)
                )
            }
        }
        return await .result(value: "", view: IssueView())
    }

    private struct IssueView: View {
        var body: some View {
            Label("intent.publish.any.issue", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.red)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding()
                .background(Color.black)
                .clipShape(Capsule())
                .padding(.horizontal)
        }
    }

    private struct StatusSuccess: View {
        var acc: AccountEntity
        var json: StatusData

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 7.5) {
                    Text("@\(acc.username)")
                        .foregroundStyle(Color.white)
                        .bold()

                    Text(json.status)
                        .foregroundStyle(Color.white)
                        .lineLimit(2)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical)
            .padding(.horizontal, 25)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 19.0))
            .padding(.horizontal)
        }
    }
}

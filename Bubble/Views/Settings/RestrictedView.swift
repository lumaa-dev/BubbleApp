//Made by Lumaa

import SwiftUI

struct RestrictedView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    
    @State private var foundAccounts: [Account] = []
    @State private var foundRelations: [Relationship] = []
    @State private var blockedDomains: [String] = []
    
    var body: some View {
        List {
            if foundAccounts.count > 0 && foundRelations.count > 0 {
                ForEach(foundAccounts) { acc in
                    let correctRelation: Relationship = foundRelations.filter({ $0.id == acc.id })[0]
                    let restrictionType: RestrictionType = .find(isMuted: correctRelation.muting, isBlocked: correctRelation.blocking)
                    
                    AccountRow(acct: acc.acct) {
                        restrictionType.rowLabel()
                    }
                    .listRowThreaded()
                }
            }
            if blockedDomains.count > 0 {
                ForEach(blockedDomains, id: \.self) { dom in
                    let restrictionType: RestrictionType = .blockedDomains
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 3.5) {
                            restrictionType.rowLabel()
                            
                            Text(dom)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    .listRowThreaded()
                }
            }
            if foundAccounts.count <= 0 && blockedDomains.count <= 0 {
                ContentUnavailableView("restricted.no-restricted", systemImage: "person.and.background.dotted", description: Text("restricted.no-restricted.description"))
                    .listRowThreaded()
            }
        }
        .task {
            await refresh()
        }
        .refreshable {
            await refresh()
        }
        .navigationTitle(Text("settings.privacy.restricted"))
        .navigationBarTitleDisplayMode(.inline)
        .listThreaded()
    }
    
    private func refresh() async {
        guard let client = accountManager.getClient() else { return }
        foundAccounts = []
        
        do {
            let muted: [Account] = try await client.get(endpoint: Restricted.mutes(maxId: nil))
            let blocked: [Account] = try await client.get(endpoint: Restricted.blockedUsers(maxId: nil))
            
            blockedDomains = try await client.get(endpoint: Restricted.blockedDomains(maxId: nil))
            foundAccounts.append(contentsOf: muted)
            foundAccounts.append(contentsOf: blocked)
            
            foundRelations = try await client.get(endpoint: Accounts.relationships(ids: foundAccounts.map({ $0.id })))
        } catch {
            print(error)
        }
    }
    
    func asyncAction(endpoint: Endpoint) {
        guard let client = accountManager.getClient() else { return }
        
        Task {
            _ = try await client.post(endpoint: endpoint)
        }
    }
}

public enum RestrictionType {
    case muted
    case blockedUsers
    case blockedDomains
    
    static func find(isMuted: Bool = false, isBlocked: Bool = false, isBlockedDomain: Bool = false) -> RestrictionType {
        if isMuted && !isBlocked {
            return RestrictionType.muted
        } else if isBlocked {
            return RestrictionType.blockedUsers
        } else if isBlockedDomain {
            return RestrictionType.blockedDomains
        }
        return RestrictionType.muted
    }
    
    func localizedTitle() -> LocalizedStringKey {
        switch self {
            case .muted:
                return .init("restricted.mutes")
            case .blockedUsers:
                return .init("restricted.users")
            case .blockedDomains:
                return .init("restricted.domains")
        }
    }
    
    func localizedType() -> LocalizedStringKey {
        switch self {
            case .muted:
                return .init("restricted.muted")
            case .blockedUsers:
                return .init("restricted.blocked-user")
            case .blockedDomains:
                return .init("restricted.blocked-domain")
        }
    }
    
    func assimilatedIcon() -> String {
        switch self {
            case .muted:
                return "speaker.slash.fill"
            case .blockedUsers:
                return "hand.raised.slash.fill"
            case .blockedDomains:
                return "network.slash"
        }
    }
    
    func assimilatedColor() -> Color {
        switch self {
            case .muted:
                return Color.yellow
            case .blockedUsers:
                return Color.orange
            case .blockedDomains:
                return Color.red
        }
    }
    
    @ViewBuilder
    func rowLabel() -> some View {
        HStack {
            Image(systemName: self.assimilatedIcon())
                .font(.body.bold())
                .foregroundStyle(self.assimilatedColor())
            
            Text(self.localizedType())
                .accountRowLabel(self.assimilatedColor())
        }
    }
}

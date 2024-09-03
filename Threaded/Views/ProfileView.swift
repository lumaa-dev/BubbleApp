//Made by Lumaa

import SwiftUI

struct ProfileView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(UniversalNavigator.self) private var uniNav: UniversalNavigator
    @Environment(AppDelegate.self) private var appDelegate: AppDelegate
    @Environment(\.openURL) private var openURL: OpenURLAction
    @EnvironmentObject private var navigator: Navigator
    
    @Namespace var accountAnims
    @Namespace var animPicture
    @State private var biggerPicture: Bool = false
    
    @State private var canFollow: Bool? = nil
    @State private var initialFollowing: Bool = false
    @State private var isFollowing: Bool = false
    @State private var accountFollows: Bool = false
    
    @State private var accountMuted: Bool = false
    @State private var accountBlocked: Bool = false
    @State private var instanceBlocked: Bool = false
    
    @State private var loadingStatuses: Bool = false
    @State private var statuses: [Status]? = []
    @State private var statusesPinned: [Status]? = []
    @State private var lastSeen: Int?
    
    private let animPicCurve = Animation.smooth(duration: 0.25, extraBounce: 0.0)
    
    @State public var account: Account
    var isCurrent: Bool = false

    //MARK: Sub Club

    /// Account ACCT ends with `sub.club`
    private var isSubClub: Bool {
        account.acct.split(separator: "@").last == "sub.club"
    }
    /// Account field that may contain `sub.club` user
    private var hasSubClub: Account.Field? {
        account.fields.filter({ $0.value.asRawText.contains(/(@)?[A-Za-z0-9_]+@sub\.club/) }).first
    }
    /// Subscribed to the Sub Club account
    @State private var isSubscribed: Bool = false

    var body: some View {
        ZStack (alignment: .center) {
            if account != Account.placeholder() {
                if biggerPicture {
                    big
                        .navigationBarBackButtonHidden()
                        .toolbar(.hidden, for: .navigationBar)
                } else {
                    wholeSmall
                        .offset(y: isCurrent ? 50 : 0)
                        .toolbar {
                            if !isCurrent {
                                ToolbarItem(placement: .primaryAction) {
                                    Menu {
                                        if accountMuted {
                                            Button {
                                                guard let client = accountManager.getClient() else { return }
                                                
                                                Task {
                                                    do {
                                                        _ = try await client.post(endpoint: Accounts.unmute(id: account.id))
                                                        accountMuted = false
                                                        HapticManager.playHaptics(haptics: Haptic.success)
                                                    } catch {
                                                        HapticManager.playHaptics(haptics: Haptic.error)
                                                        print(error)
                                                    }
                                                }
                                            } label: {
                                                Label("account.unmute", systemImage: "speaker.wave.2.fill")
                                            }
                                        } else {
                                            Menu {
                                                ForEach(MuteData.MuteDuration.allCases, id: \.self) { duration in
                                                    Button {
                                                        guard let client = accountManager.getClient() else { return }
                                                        
                                                        Task {
                                                            do {
                                                                _ = try await client.post(endpoint: Accounts.mute(id: account.id, json: .init(duration: duration.rawValue)))
                                                                accountMuted = true
                                                                HapticManager.playHaptics(haptics: Haptic.success)
                                                            } catch {
                                                                HapticManager.playHaptics(haptics: Haptic.error)
                                                                print(error)
                                                            }
                                                        }
                                                    } label: {
                                                        Text(duration.description)
                                                    }
                                                }
                                            } label: {
                                                Label("account.mute", systemImage: "speaker.slash")
                                            }
                                        }
                                        
                                        Button(role: accountBlocked ? .cancel : .destructive) {
                                            guard let client = accountManager.getClient() else { return }
                                            
                                            Task {
                                                do {
                                                    let endp: Endpoint = accountBlocked ? Accounts.unblock(id: account.id) : Accounts.block(id: account.id)
                                                    _ = try await client.post(endpoint: endp)
                                                    accountBlocked.toggle()
                                                    HapticManager.playHaptics(haptics: Haptic.success)
                                                } catch {
                                                    HapticManager.playHaptics(haptics: Haptic.error)
                                                    print(error)
                                                }
                                            }
                                        } label: {
                                            Label(accountBlocked ? "account.unblock" : "account.block", systemImage: accountBlocked ? "person.fill.badge.plus" : "person.slash.fill")
                                        }
                                    } label: {
                                        Image(systemName: "shield.righthalf.filled")
                                            .font(.title2)
                                    }
                                }
                            }
                        }
                        .overlay(alignment: .top) {
                            if isCurrent {
                                HStack {
                                    Button {
                                        navigator.navigate(to: .support)
                                    } label: {
                                        Image(systemName: "info.bubble")
                                            .font(.title2)
                                    }
                                    
                                    Spacer() // middle seperation
                                    
                                    Button {
                                        navigator.navigate(to: .settings)
                                    } label: {
                                        Image(systemName: "text.alignright")
                                            .font(.title2)
                                    }
                                }
                                .tint(Color(uiColor: UIColor.label))
                                .safeAreaPadding()
                                .background(Color.appBackground)
                            }
                        }
                }
            } else {
                loading
            }
        }
        .task {
            await reloadUser()
            initialFollowing = isFollowing
        }
        .refreshable {
            if isCurrent {
                guard let client = accountManager.getClient() else { return }
                if let acc: Account = try? await client.get(endpoint: Accounts.verifyCredentials) {
                    account = acc
                }
            }
            
            await reloadUser()
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.automatic, for: .navigationBar)
    }
    
    // MARK: - Headers
    
    var wholeSmall: some View {
        ScrollView {
            VStack {
                VStack (alignment: .leading) {
                    if account.haveHeader {
                        AsyncImage(url: account.header, scale: 1.0) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: appDelegate.windowWidth - 50, height: appDelegate.windowHeight / 5)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 15.0))
                                .padding(.bottom)
                        } placeholder: {
                            EmptyView()
                        }
                        .onTapGesture {
                            let attachment: MediaAttachment = .init(id: account.id, type: "image", url: account.header)
                            navigator.presentedCover = .media(attachments: [attachment], selected: attachment)
                        }
                    }
                    
                    unbig
                    
                    Text(account.note.asRawText)
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 5)
                    
                    if account.fields.count > 0 {
                        fields
                            .padding(.vertical)
                    }
                    
                    let followCount = (account.followersCount ?? 0 - (initialFollowing ? 1 : 0)) + (isFollowing ? 1 : 0)
                    Text("account.followers-\(followCount)")
                        .foregroundStyle(Color.gray)
                        .multilineTextAlignment(.leading)
                        .font(.callout)

                    VStack {
                        if let field = hasSubClub, (canFollow ?? true) == true {
                            Button {
                                guard !isSubscribed, let extracted = field.extractSubclub(), let usrnme: Substring = extracted.split(separator: "@").first, let userAcc = accountManager.getAccount(), let cliAcc = accountManager.getClient() else {
                                    return
                                }

                                let subclubUrl: URL = URL(
                                    string: "https://sub.club/@\(usrnme)/subscribe?callback=threadedapp://subclub&id=@\(userAcc.username)@\(cliAcc.server)&theme=dark"
                                )!
                                print(subclubUrl.absoluteString)
                                uniNav.presentedSheet = .safari(url: subclubUrl)
                            } label: {
                                HStack {
                                    Spacer()
                                    Text(isSubscribed ? "account.subsclub.subscribed" : "account.subclub.subscribe")
                                        .font(.callout)
                                    Spacer()
                                }
                            }
                            .buttonStyle(LargeButton(filled: true, filledColor: Color.subClub, height: 10))
                            .disabled(isSubscribed)
                        }

                        if canFollow != nil && (canFollow ?? true) == true {
                            HStack (spacing: 5) {
                                Button {
                                    Task {
                                        await followAccount()
                                    }
                                } label: {
                                    HStack {
                                        Spacer()
                                        Text(isFollowing ? "account.unfollow" : accountFollows ? "account.follow-back" : "account.follow")
                                            .font(.callout)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(LargeButton(filled: true, height: 10))

                                Button {
                                    if let server = account.acct.split(separator: "@").last {
                                        uniNav.presentedSheet = .post(content: "@\(account.username)@\(server)")
                                    } else {
                                        let client = accountManager.getClient()
                                        uniNav.presentedSheet = .post(content: "@\(account.username)@\(client?.server ?? "???")")
                                    }
                                } label: {
                                    HStack {
                                        Spacer()
                                        Text("account.mention")
                                            .font(.callout)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(LargeButton(filled: false, height: 10))
                            }
                        }
                    }

                    if isCurrent {
                        Button {
                            uniNav.presentedSheet = .profEdit
                        } label: {
                            HStack {
                                Spacer()
                                Text("account.edit")
                                    .font(.callout)
                                Spacer()
                            }
                        }
                        .buttonStyle(LargeButton(filled: true, height: 10))
                    }
                }
                .padding(.horizontal)
                
                VStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: .infinity, height: 1)
                        .padding(.bottom, 3)
                    
                    statusesList
                }
            }
            .safeAreaPadding(.vertical)
            .padding(.horizontal)
        }
    }
    
    var fields: some View {
        VStack(alignment: .leading, spacing: 7.5) {
            ForEach(account.fields) { field in
                HStack {
                    if field.verifiedAt == nil {
                        Text(field.name)
                            .lineLimit(1)
                    } else {
                        Label(field.name, systemImage: "checkmark.seal.fill")
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    TextEmoji(field.value, emojis: account.emojis)
                }
                .onTapGesture {
                    if let url = URL(string: field.value.asRawText) {
                        HapticManager.playHaptics(haptics: Haptic.success)
                        openURL(url)
                    } else {
                        HapticManager.playHaptics(haptics: Haptic.error)
                    }
                }
                .foregroundStyle(field.verifiedAt == nil ? Color.gray : Color.green)
            }
        }
    }
    
    var statusesList: some View {
        LazyVStack {
            if loadingStatuses == false {
                if !(statusesPinned?.isEmpty ?? true) {
                    ForEach(statusesPinned!, id: \.id) { status in
                        CompactPostView(status: status, pinned: true)
                    }
                }
                if !(statuses?.isEmpty ?? true) {
                    ForEach(statuses!, id: \.id) { status in
                        CompactPostView(status: status)
                            .onDisappear() {
                                lastSeen = statuses!.firstIndex(where: { $0.id == status.id })
                            }
                    }
                } else {
                    ContentUnavailableView(account.locked ? "account.private" : "account.no-statuses", systemImage: account.locked ? "lock.fill" : "pencil.slash")
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .onAppear {
            if statuses == nil {
                if let client = accountManager.getClient() {
                    Task {
                        loadingStatuses = true
                        statuses = try await client.get(endpoint: Accounts.statuses(id: account.id, sinceId: nil, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: nil))
                        statusesPinned = try await client.get(endpoint: Accounts.statuses(id: account.id, sinceId: nil, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: true))
                        loadingStatuses = false
                    }
                }
            }
        }
        .onChange(of: lastSeen ?? 0) { _, new in
            guard statuses != nil && new >= statuses!.count - 6 && !loadingStatuses else { return }
            if let client = accountManager.getClient(), let lastStatus = statuses!.last {
                Task {
//                    loadingStatuses = true
                    if let newStatuses: [Status] = try await client.get(endpoint: Accounts.statuses(id: account.id, sinceId: lastStatus.id, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: nil)) {
                        statuses?.append(contentsOf: newStatuses)
                    }
//                    loadingStatuses = false
                }
            }
        }
    }
    
    func followAccount() async {
        if let client = accountManager.getClient() {
            Task {
                let endpoint: Endpoint = isFollowing ? Accounts.unfollow(id: account.id) : Accounts.follow(id: account.id, notify: false, reblogs: true)
                HapticManager.playHaptics(haptics: Haptic.tap)
                _ = try await client.post(endpoint: endpoint) // Notify off until APNs? | Reblogs on by default (later changeable)
                isFollowing = !isFollowing
            }
        }
    }
    
    func reloadUser() async {
        if let client = accountManager.getClient() {
            var accId: String = account.id
            if isCurrent, let acc = accountManager.getAccount() {
                accId = acc.id
            }
            
            if let ref: Account = try? await client.get(endpoint: Accounts.accounts(id: accId)) {
                account = ref
                if let subClubAcc = await getSubclubAccount() {
                    await updateRelationship(with: [subClubAcc.id], subClubId: subClubAcc.id)
                } else {
                    await updateRelationship()
                }


                loadingStatuses = true
                statuses = try? await client.get(endpoint: Accounts.statuses(id: accId, sinceId: nil, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: nil))
                statusesPinned = try? await client.get(endpoint: Accounts.statuses(id: accId, sinceId: nil, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: true))
                loadingStatuses = false
            }
        }
    }
    
    func updateRelationship(with other: [String] = [], subClubId: String? = nil) async {
        if let client = accountManager.getClient() {
            if let currentAccount: Account = try? await client.get(endpoint: Accounts.verifyCredentials) {
                canFollow = currentAccount.id != account.id
                guard canFollow == true else { return }

                var relsId: [String] = [account.id]
                relsId.append(contentsOf: other)

                if let relationship: [Relationship] = try? await client.get(endpoint: Accounts.relationships(ids: relsId)) {
                    let rel: Relationship = relationship.first! // the searched up account
                    isFollowing = rel.following
                    accountFollows = rel.followedBy
                    accountMuted = rel.muting
                    accountBlocked = rel.blocking

                    if let subClubId {
                        guard let subClubRel: Relationship = relationship.filter({ $0.id == subClubId }).first else {
                            fatalError("The SubClub Relationship ID doesn't match")
                        }

                        isSubscribed = subClubRel.following
                    }
                }
            } else {
                canFollow = false
            }
        }
    }

    private func getSubclubAccount() async -> Account? {
        if let field = hasSubClub, let acct = field.extractSubclub(), let client = accountManager.getClient() {
            if let res: SearchResults = try? await client.post(
                endpoint: Search.accountsSearch(query: acct, type: nil, offset: 0, following: nil)
            ), !res.isEmpty, !res.accounts.isEmpty {
                let subclub = res.accounts.first!
                return subclub
            }
        }
        return nil
    }

    var loading: some View {
        ScrollView {
            VStack {
                unbig
                    .redacted(reason: .placeholder)
                
                HStack {
                    Text(account.note.asRawText)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .redacted(reason: .placeholder)
                    
                    Spacer()
                }
            }
            .safeAreaPadding(.vertical)
            .padding(.horizontal)
        }
    }
    
    var unbig: some View {
        HStack {
            if account.displayName != nil {
                VStack(alignment: .leading) {
                    Text(account.displayName!)
                        .font(.title2.bold())
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    let server = account.acct.split(separator: "@").last
                    let client = accountManager.getClient()
                    
                    usernameView(client, server)
                }
            } else {
                Text(account.acct)
                    .font(.headline)
            }
            
            Spacer()
            
            profilePicture
                .frame(width: 75, height: 75)
        }
    }

    @ViewBuilder
    func usernameView(_ client: Client?, _ server: Substring?) -> some View {
        HStack(alignment: .center) {
            if let server {
                if server != account.username {
                    Text("\(account.username)")
                        .font(.body)
                        .multilineTextAlignment(.leading)

                    Text("\(server.description)")
                        .font(.caption)
                        .foregroundStyle(!isSubClub ? Color.gray : Color.subClub)
                        .multilineTextAlignment(.leading)
                        .pill(tint: !isSubClub ? Color(uiColor: UIColor.label) : Color.subClub)
                } else {
                    Text("\(account.username)")
                        .font(.body)
                        .multilineTextAlignment(.leading)

                    Text("\(client?.server ?? "???")")
                        .font(.caption)
                        .foregroundStyle(!isSubClub ? Color.gray : Color.subClub)
                        .multilineTextAlignment(.leading)
                        .pill(tint: !isSubClub ? Color(uiColor: UIColor.label) : Color.subClub)
                }
            } else {
                Text("\(account.username)")
                    .font(.body)
                    .multilineTextAlignment(.leading)

                Text("\(client?.server ?? "???")")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                    .multilineTextAlignment(.leading)
                    .pill()
            }
        }
    }

    var big: some View {
        ZStack (alignment: .center) {
            Rectangle()
                .fill(Material.ultraThin)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(animPicCurve) {
                        biggerPicture.toggle()
                    }
                }
            
            profilePicture
                .frame(width: 300, height: 300)
        }
        .zIndex(20)
    }
    
    var profilePicture: some View {
        ProfilePicture(url: account.avatar, size: biggerPicture ? 300 : 75)
            .matchedGeometryEffect(id: animPicture, in: accountAnims)
            .onTapGesture {
                withAnimation(animPicCurve) {
                    biggerPicture.toggle()
                }
            }
    }
}

extension Color {
    static let subClub: Color = Color(red: 0.91, green: 0.43, blue: 0.23)
}

private extension View {
    func pill(tint: Color = Color(uiColor: UIColor.label)) -> some View {
        self
            .padding([.horizontal], 10)
            .padding([.vertical], 5)
            .background(tint.opacity(0.1))
            .clipShape(.capsule)
    }
}

private extension Account.Field {
    /// Extracts the full acct of the Sub Club username in the field
    func extractSubclub() -> String? {
        if let match = self.value.asRawText.firstMatch(of: /(@)?[A-Za-z0-9_]+@sub\.club/) {
            return "\(match.output.0)"
        }
        return nil
    }
}

//Made by Lumaa

import SwiftUI

struct CompactPostView: View {
    @Environment(Client.self) private var client: Client
    var status: Status
    var navigator: Navigator
    
    @State private var isLiked: Bool = false
    @State private var isReposted: Bool = false
    
    @State private var incrLike: Bool = false
    
    var body: some View {
        VStack {
            if status.reblog != nil {
                VStack(alignment: .leading) {
                    repostNotice
                        .padding(.leading, 40)
                    
                    statusRepost
                }
            } else {
                statusPost
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: .infinity, height: 1)
                .padding(.bottom, 3)
        }
        .onAppear {
            isLiked = status.reblog != nil ? status.reblog!.favourited ?? false : status.favourited ?? false
            isReposted = status.reblog != nil ? status.reblog!.reblogged ?? false : status.reblogged ?? false
        }
    }
    
    func likePost() async throws {
        guard client.isAuth else { fatalError("Client is not authenticated") }
        let statusId: String = status.reblog != nil ? status.reblog!.id : status.id
        let endpoint = !isLiked ? Statuses.favorite(id: statusId) : Statuses.unfavorite(id: statusId)
        
        isLiked = !isLiked
        let newStatus: Status = try await client.post(endpoint: endpoint)
        if isLiked != newStatus.favourited {
            isLiked = newStatus.favourited ?? !isLiked
        }
    }
    
    func repostPost() async throws {
        guard client.isAuth else { fatalError("Client is not authenticated") }
        let statusId: String = status.reblog != nil ? status.reblog!.id : status.id
        let endpoint = !isReposted ? Statuses.reblog(id: statusId) : Statuses.unreblog(id: statusId)
        
        isReposted = !isReposted
        let newStatus: Status = try await client.post(endpoint: endpoint)
        if isReposted != newStatus.reblogged {
            isReposted = newStatus.reblogged ?? !isReposted
        }
    }
    
    var statusPost: some View {
        HStack(alignment: .top, spacing: 0) {
            // MARK: Profile picture
            if status.repliesCount > 0 {
                VStack {
                    profilePicture
                        .onTapGesture {
                            navigator.navigate(to: .account(acc: status.account))
                        }
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2.5)
                        .clipShape(.capsule)
                        .padding([.vertical], 5)
                    
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(Color.gray.opacity(0.3))
                        .padding(.bottom, 2.5)
                }
            } else {
                profilePicture
                    .onTapGesture {
                        navigator.navigate(to: .account(acc: status.account))
                    }
            }
            
            VStack(alignment: .leading) {
                // MARK: Status main content
                VStack(alignment: .leading, spacing: 10) {
                    Text(status.account.username)
                        .multilineTextAlignment(.leading)
                        .bold()
                        .onTapGesture {
                            navigator.navigate(to: .account(acc: status.account))
                        }
                    
                    Text(status.content.asRawText)
                        .multilineTextAlignment(.leading)
                        .frame(width: 300, alignment: .topLeading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                //MARK: Action buttons
                HStack(spacing: 13) {
                    asyncActionButton(isLiked ? "heart.fill" : "heart") {
                        do {
                            HapticManager.playHaptics(haptics: Haptic.tap)
                            try await likePost()
                        } catch {
                            HapticManager.playHaptics(haptics: Haptic.error)
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                    actionButton("bubble.right") {
                        print("reply")
                        navigator.presentedSheet = .post
                    }
                    asyncActionButton(isReposted ? "bolt.horizontal.fill" : "bolt.horizontal") {
                        do {
                            HapticManager.playHaptics(haptics: Haptic.tap)
                            try await repostPost()
                        } catch {
                            HapticManager.playHaptics(haptics: Haptic.error)
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                    ShareLink(item: URL(string: status.url ?? "https://joinmastodon.org/")!) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                    }
                    .tint(Color(uiColor: UIColor.label))
                }
                .padding(.top)
                
                // MARK: Status stats
                stats.padding(.top, 5)
            }
        }
    }
    
    var statusRepost: some View {
        HStack(alignment: .top, spacing: 0) {
            // MARK: Profile picture
            if status.reblog!.repliesCount > 0 {
                VStack {
                    profilePicture
                        .onTapGesture {
                            navigator.navigate(to: .account(acc: status.reblog!.account))
                        }
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2.5)
                        .clipShape(.capsule)
                        .padding([.vertical], 5)
                    
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(Color.gray.opacity(0.3))
                        .padding(.bottom, 2.5)
                }
            } else {
                profilePicture
                    .onTapGesture {
                        navigator.navigate(to: .account(acc: status.reblog!.account))
                    }
            }
            
            VStack(alignment: .leading) {
                // MARK: Status main content
                VStack(alignment: .leading, spacing: 10) {
                    Text(status.reblog!.account.username)
                        .multilineTextAlignment(.leading)
                        .bold()
                        .onTapGesture {
                            navigator.navigate(to: .account(acc: status.reblog!.account))
                        }
                    
                    Text(status.reblog!.content.asRawText)
                        .multilineTextAlignment(.leading)
                        .frame(width: 300, alignment: .topLeading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                //MARK: Action buttons
                HStack(spacing: 13) {
                    asyncActionButton(isLiked ? "heart.fill" : "heart") {
                        do {
                            HapticManager.playHaptics(haptics: Haptic.tap)
                            try await likePost()
                            incrLike = isLiked
                        } catch {
                            HapticManager.playHaptics(haptics: Haptic.error)
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                    actionButton("bubble.right") {
                        print("reply")
                        navigator.presentedSheet = .post
                    }
                    asyncActionButton(isReposted ? "bolt.horizontal.fill" : "bolt.horizontal") {
                        do {
                            HapticManager.playHaptics(haptics: Haptic.tap)
                            try await repostPost()
                        } catch {
                            HapticManager.playHaptics(haptics: Haptic.error)
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                    ShareLink(item: URL(string: status.reblog!.url ?? "https://joinmastodon.org/")!) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                    }
                    .tint(Color(uiColor: UIColor.label))
                }
                .padding(.top)
                
                // MARK: Status stats
                stats.padding(.top, 5)
            }
        }
    }
    
    var repostNotice: some View {
        HStack (alignment:.center, spacing: 5) {
            Image(systemName: "bolt.horizontal")
            
            Text("status.reposted-by.\(status.account.username)")
        }
        .padding(.leading, 25)
        .multilineTextAlignment(.leading)
        .lineLimit(1)
        .font(.caption)
        .foregroundStyle(Color(uiColor: UIColor.label).opacity(0.3))
    }
    
    var profilePicture: some View {
        if status.reblog != nil {
            OnlineImage(url: status.reblog!.account.avatar)
                .frame(width: 40, height: 40)
                .padding(.horizontal)
                .clipShape(.circle)
        } else {
            OnlineImage(url: status.account.avatar)
                .frame(width: 40, height: 40)
                .padding(.horizontal)
                .clipShape(.circle)
        }
    }
    
    var stats: some View {
        if status.reblog == nil {
            HStack {
                if status.repliesCount > 0 {
                    Text("status.replies-\(status.repliesCount)")
                        .monospacedDigit()
                        .foregroundStyle(.gray)
                }
                
                if status.repliesCount > 0 && (status.favouritesCount > 0 || isLiked) {
                    Text("•")
                        .foregroundStyle(.gray)
                }
                
                if status.favouritesCount > 0 || isLiked {
                    let addedLike: Int = incrLike ? 1 : 0
                    Text("status.favourites-\(status.favouritesCount + addedLike)")
                        .monospacedDigit()
                        .foregroundStyle(.gray)
                        .contentTransition(.numericText(value: Double(status.favouritesCount + addedLike)))
                        .transaction { t in
                            t.animation = .default
                        }
                }
            }
        } else {
            HStack {
                if status.reblog!.repliesCount > 0 {
                    Text("status.replies-\(status.reblog!.repliesCount)")
                        .monospacedDigit()
                        .foregroundStyle(.gray)
                }
                
                if status.reblog!.repliesCount > 0 && (status.reblog!.favouritesCount > 0 || isLiked) {
                    Text("•")
                        .foregroundStyle(.gray)
                }
                
                if status.reblog!.favouritesCount > 0 || isLiked {
                    let addedLike: Int = incrLike ? 1 : 0
                    Text("status.favourites-\(status.reblog!.favouritesCount + addedLike)")
                        .monospacedDigit()
                        .foregroundStyle(.gray)
                        .contentTransition(.numericText(value: Double(status.reblog!.favouritesCount + addedLike)))
                        .transaction { t in
                            t.animation = .default
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    func actionButton(_ image: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: image)
                .font(.title2)
        }
        .tint(Color(uiColor: UIColor.label))
    }
    
    @ViewBuilder
    func asyncActionButton(_ image: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task {
                await action()
            }
        } label: {
            Image(systemName: image)
                .font(.title2)
        }
        .tint(Color(uiColor: UIColor.label))
    }
}

#Preview {
    ScrollView {
        VStack {
            ForEach(Status.placeholders()) { status in
                CompactPostView(status: status, navigator: Navigator())
                    .environment(Client.init(server: AppInfo.defaultServer))
            }
        }
    }
}

//Made by Lumaa

import SwiftUI

struct PostDetailsView: View {
    @EnvironmentObject private var navigator: Navigator
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(AppDelegate.self) private var delegate: AppDelegate
    
    var detailedStatus: Status
    
    @State private var statuses: [Status] = []
    @State private var scrollId: String? = nil
    @State private var initialLike: Bool = false
    
    @State private var isLiked: Bool = false
    @State private var isReposted: Bool = false
    @State private var isBookmarked: Bool = false
    
    @State private var hasQuote: Bool = false
    @State private var quoteStatus: Status? = nil
    
    init(status: Status) {
        self.detailedStatus = status.reblogAsAsStatus ?? status
    }
    
    var body: some View {
        ScrollView(.vertical) {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 1.5) {
                    if statuses.isEmpty {
                        CompactPostView(status: detailedStatus)
                    } else {
                        ForEach(statuses) { status in
                            let isLast: Bool = status.id == statuses.last?.id ?? ""

                            if status.id == detailedStatus.id {
                                CompactPostView(status: detailedStatus)
                                    .onAppear {
                                        proxy.scrollTo("\(detailedStatus.id)@\(detailedStatus.account.id)", anchor: .bottom)
                                    }
                            } else {
                                repPost(status)
                            }

                            if !isLast {
                                Divider()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .task {
                    await fetchStatusDetail()
                }
            }
        }
        .background(Color.appBackground)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .safeAreaPadding()
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    func repPost(_ status: Status) -> some View {
        HStack(alignment: .center, spacing: 8.0) {
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(maxWidth: 2.0, maxHeight: .infinity, alignment: .leading)

            CompactPostView(status: status)
        }
    }

    private func fetchStatusDetail() async {
        guard let client = accountManager.getClient() else { return }
        do {
            let data = try await fetchContextData(client: client, statusId: detailedStatus.id)
            
            var statusesContext = data.context.ancestors
            statusesContext.append(data.status)
            statusesContext.append(contentsOf: data.context.descendants)
            
            statuses = statusesContext
            
//            await loadEmbeddedStatus()
        } catch {
            if let error = error as? ServerError, error.httpCode == 404 {
                _ = navigator.path.popLast()
            }
        }
    }
    
    private func fetchContextData(client: Client, statusId: String) async throws -> ContextData {
        async let status: Status = client.get(endpoint: Statuses.status(id: statusId))
        async let context: StatusContext = client.get(endpoint: Statuses.context(id: statusId))
        return try await .init(status: status, context: context)
    }
    
    struct ContextData {
        let status: Status
        let context: StatusContext
    }

    private func embededStatusURL() -> URL? {
        let content = detailedStatus.content
        if let client = accountManager.getClient() {
            if !content.statusesURLs.isEmpty, let url = content.statusesURLs.first, client.hasConnection(with: url) {
                return url
            }
        }
        return nil
    }
    
    func loadEmbeddedStatus() async {
        guard let url = embededStatusURL(), let client = accountManager.getClient() else { hasQuote = false; return }
        
        do {
            hasQuote = true
            if url.absoluteString.contains(client.server), let id = Int(url.lastPathComponent) {
                quoteStatus = try await client.get(endpoint: Statuses.status(id: String(id)))
            } else {
                let results: SearchResults = try await client.get(endpoint: Search.search(query: url.absoluteString, type: "statuses", offset: 0, following: nil), forceVersion: .v2)
                quoteStatus = results.statuses.first
            }
        } catch {
            hasQuote = false
            quoteStatus = nil
        }
    }
}

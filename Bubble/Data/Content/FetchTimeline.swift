//Made by Lumaa

import Foundation

class FetchTimeline {
    var client: Client?
    public private(set) var datasource: [Status] = []
    public var statusesState: LoadingState = .loading
    
    private var timeline: TimelineFilter = .home
    public private(set) var filtering: Bool = false
    public private(set) var lastFilter: PostFilter? = nil
    
    init(client: Client) {
        self.client = client
    }
    
    init() {
        self.client = nil
    }
    
    public func fetch(client: Client) async -> [Status] {
        self.client = client
        self.statusesState = .loading
        self.datasource = await fetchNewestStatuses()
        self.statusesState = .loaded
        return self.datasource
    }
    
    public func addStatuses(lastStatusIndex: Int) async -> [Status] {
//        print("i: \(lastStatusIndex)\ndatasource-6: \(self.datasource.count - 6)")
        guard client != nil && lastStatusIndex >= self.datasource.count - 6 && !self.datasource.isEmpty else {
            return self.datasource
        }
        
        self.statusesState = .loading
        let lastStatus = self.datasource.last!
        let newStatuses: [Status] = await fetchNewestStatuses(lastStatusId: lastStatus.id, filter: lastFilter)
        self.datasource.append(contentsOf: newStatuses)
        self.statusesState = .loaded
            
        print("added posts")
        return self.datasource
    }
    
    private func fetchNewestStatuses(lastStatusId: String? = nil, filter: PostFilter? = nil) async -> [Status] {
        guard client != nil else { return [] }
        do {
            var statuses: [Status] = try await client!.get(endpoint: timeline.endpoint(sinceId: nil, maxId: lastStatusId, minId: nil, offset: 0))
            statuses = applyContentFilter(statuses, filter: filter)
            self.lastFilter = filter
            if lastStatusId == nil {
                self.datasource = statuses
            }
            self.statusesState = .loaded
            return statuses
        } catch {
            statusesState = .error(error: error)
            print("timeline parse error: \(error)")
        }
        return []
    }
    
    func setTimelineFilter(_ filter: TimelineFilter) {
        self.timeline = filter
    }
    
    func useContentFilter(_ filter: PostFilter) async -> [Status] {
        self.datasource = []
        self.statusesState = .loading
        return await self.fetchNewestStatuses(lastStatusId: nil, filter: filter)
    }
    
    private func applyContentFilter(_ statuses: [Status], filter: PostFilter? = nil) -> [Status] {
        guard let postFilter = filter else { return statuses }
        var filteredStatuses: [Status] = statuses
        let contentFilter: any PostFilter = postFilter
        
        let filterType: ContentFilter.FilterType = UserDefaults.standard.bool(forKey: "censorsFilter") ? .censor : .remove
        
        for post in statuses {
            let i = statuses.firstIndex(of: post) ?? -1
            
            let isFiltered = contentFilter.filter(post, type: filterType) { sensitive in
                post.content.asRawText = post.content.asRawText.replacingOccurrences(of: sensitive, with: "***")
                post.content.asMarkdown = post.content.asMarkdown.replacingOccurrences(of: sensitive, with: "***")
                post.content.asSafeMarkdownAttributedString = post.content.asSafeMarkdownAttributedString.replacing(sensitive, with: "***")
                
                filteredStatuses[i] = post
                
                print("Censored \(post.account.acct)'s post")
            }
            
            if isFiltered && filterType == .remove {
                filteredStatuses.remove(at: i)
                
                print("Removed \(post.account.acct)'s post")
            }
        }
        
        return filteredStatuses
    }
    
    func toggleContentFilter(filter: PostFilter) async -> [Status] {
        if self.filtering {
            self.lastFilter = nil
            self.filtering = false
            
            self.datasource = []
            self.statusesState = .loading
            return await self.fetchNewestStatuses(lastStatusId: nil, filter: nil)
        } else {
            self.lastFilter = filter
            self.filtering = true
            
            return await self.useContentFilter(filter)
        }
    }
    
    func getStatuses() -> [Status] {
        return datasource
    }
    
    enum LoadingState {
        case loading
        case loaded
        case error(error: Error)
    }
}

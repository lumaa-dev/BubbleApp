//Made by Lumaa

import Foundation

struct FetchTimeline {
    var client: Client?
    public private(set) var datasource: [Status] = []
    public var statusesState: LoadingState = .loading
    
    private var timeline: TimelineFilter = .home
    
    init(client: Client) {
        self.client = client
    }
    
    init() {
        self.client = nil
    }
    
    public mutating func fetch(client: Client) async -> [Status] {
        self.client = client
        self.statusesState = .loading
        self.datasource = await fetchNewestStatuses()
        self.statusesState = .loaded
        return self.datasource
    }
    
    public mutating func addStatuses(lastStatusIndex: Int) async -> [Status] {
//        print("i: \(lastStatusIndex)\ndatasource-6: \(self.datasource.count - 6)")
        guard client != nil && lastStatusIndex >= self.datasource.count - 6 else { return self.datasource }
        
        self.statusesState = .loading
        let lastStatus = self.datasource.last!
        let newStatuses: [Status] = await fetchNewestStatuses(lastStatusId: lastStatus.id)
        self.datasource.append(contentsOf: newStatuses)
        self.statusesState = .loaded
            
        print("added posts")
        return self.datasource
    }
    
    private mutating func fetchNewestStatuses(lastStatusId: String? = nil) async -> [Status] {
        guard client != nil else { return [] }
        do {
            let statuses: [Status] = try await client!.get(endpoint: timeline.endpoint(sinceId: nil, maxId: lastStatusId, minId: nil, offset: 0))
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
    
    mutating func setTimelineFilter(_ filter: TimelineFilter) {
        self.timeline = filter
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

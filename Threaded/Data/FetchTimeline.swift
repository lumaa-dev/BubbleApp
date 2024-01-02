//Made by Lumaa

import Foundation

struct FetchTimeline {
    var client: Client
    private var datasource: [Status] = []
    public var statusesState: LoadingState = .loading
    
    private var timeline: TimelineFilter = .home
    
    init(client: Client) {
        self.client = client
    }
    
    public mutating func fetch(client: Client) async {
        self.statusesState = .loading
        self.datasource = await fetchNewestStatuses()
    }
    
    private mutating func fetchNewestStatuses() async -> [Status] {
        do {
            let statuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: nil, maxId: nil, minId: nil, offset: 0))
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

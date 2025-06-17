//Made by Lumaa

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @State var navigator: Navigator = Navigator.shared
    
    @State private var showPicker: Bool = false
    @State private var timelines: [TimelineFilter] = [.home, .trending, .local, .federated]
    
    @State private var loadingStatuses: Bool = false
    @State private var statuses: [Status]?
    @State private var lastSeen: Int?
    
    @Query private var filters: [ModelFilter]
    @State private var wordsFilter: ContentFilter.WordFilter = ContentFilter.defaultFilter
    
    @State var timeline: TimelineFilter = .home
    @State var showHero: Bool = true
    @State var timelineModel: FetchTimeline // home timeline by default
    
    init(timelineModel: FetchTimeline, timeline: TimelineFilter = .home, showHero: Bool = true) {
        self.timelineModel = timelineModel
        self.timeline = timeline
        self.showHero = showHero
    }
    
    init(timeline: TimelineFilter = .home, showHero: Bool = true) {
        self.timelineModel = .init(client: AccountManager.shared.forceClient())
        self.timeline = timeline
        self.showHero = showHero
    }
    
    var body: some View {
        ZStack {
            if statuses != nil {
                if !statuses!.isEmpty {
                    statusesView
                        .refreshable {
                            if let client = accountManager.getClient() {
                                statuses = nil

                                Task {
                                    loadingStatuses = true
                                    statuses = await timelineModel.fetch(client: client)
                                    loadingStatuses = false
                                }
                            }
                        }
                        .onChange(of: lastSeen ?? 0) { _, new in
                            guard !loadingStatuses else { return }
                            Task {
                                loadingStatuses = true
                                statuses = await timelineModel.addStatuses(lastStatusIndex: new)
                                loadingStatuses = false
                            }
                        }
                } else {
                    emptyView
                }
            } else {
                loadingView
            }
        }
        .navigationTitle(Text(timeline.localizedTitle()))
        .background(Color.appBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("timeline.pick", selection: $timeline) {
                        ForEach(timelines, id: \.self) { t in
                            Label {
                                Text(t.localizedTitle())
                            } icon: {
                                t.image()
                            }
                            .id(t)
                        }
                    }
                } label: {
                    Label("timeline.pick", systemImage: "square.stack")
                }
            }

            if UserDefaults.standard.bool(forKey: "allowFilter") {
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        statuses = nil

                        Task {
                            loadingStatuses = true
                            statuses = await self.timelineModel.toggleContentFilter(filter: wordsFilter)
                            loadingStatuses = false
                        }
                    } label: {
                        Image(systemName: self.timelineModel.filtering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .symbolEffect(.pulse.wholeSymbol, isActive: self.timelineModel.filtering)
                    }
                    .tint(Color(uiColor: UIColor.label))
                }
            }
        }
        .onChange(of: timeline) { _, newValue in
            Task {
                await self.reloadTimeline(newValue)
            }
        }
    }

    // MARK: Views
    private var statusesView: some View {
        ScrollView(showsIndicators: false) {
            ForEach(statuses!, id: \.id) { status in
                let isLast: Bool = status.id == statuses!.last?.id ?? ""

                LazyVStack(alignment: .leading, spacing: 0.0) {
                    CompactPostView(status: status)
                        .onDisappear {
                            guard statuses != nil else { return }
                            lastSeen = statuses!.firstIndex(where: { $0.id == status.id })
                        }

                    if !isLast {
                        Divider()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .background(Color.appBackground)
    }

    private var emptyView: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ContentUnavailableView {
                Text("timeline.empty")
                    .bold()
            } description: {
                Text("timeline.empty.description")
            }
            .background(Color.appBackground)
        }
    }

    private var loadingView: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
                .onAppear {
                    if UserDefaults.standard.bool(forKey: "allowFilter") {
                        self.wordsFilter = filters.compactMap({ ContentFilter.WordFilter(model: $0) }).first ?? ContentFilter.defaultFilter
                    }

                    if let client = accountManager.getClient() {
                        Task {
                            statuses = await timelineModel.fetch(client: client)

                            if UserDefaults.standard.bool(forKey: "autoOnFilter") {
                                statuses = await self.timelineModel.useContentFilter(wordsFilter)
                            }
                        }
                    }
                }

            ProgressView()
                .progressViewStyle(.circular)
        }
    }

    private func reloadTimeline(_ filter: TimelineFilter) async {
        guard let client = accountManager.getClient() else { return }
        statuses = nil
        self.timeline = filter
        timelineModel.setTimelineFilter(filter)
        
        Task {
            loadingStatuses = true
            statuses = await timelineModel.fetch(client: client)
            lastSeen = nil
            
            if timelineModel.filtering {
                statuses = await self.timelineModel.useContentFilter(wordsFilter)
            }
            loadingStatuses = false
        }
    }
}

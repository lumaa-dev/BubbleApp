//Made by Lumaa

import SwiftUI

struct PostsView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
//    @State var navigator: Navigator = Navigator()
    
    @State private var showPicker: Bool = false
    @State private var stringTimeline: String = "home"
    @State private var timelines: [TimelineFilter] = [.trending, .home]
    
    @State private var loadingStatuses: Bool = false
    @State private var statuses: [Status]?
    @State private var lastSeen: Int?
    
    @State var filter: TimelineFilter = .home
    @State var showHero: Bool = true
    @State var timelineModel: FetchTimeline // home timeline by default
    
    init(filter: TimelineFilter = .home, showHero: Bool = true) {
        self.timelineModel = FetchTimeline()
        self.filter = filter
        self.showHero = showHero
        
        self.timelineModel.setTimelineFilter(self.filter)
    }
    
    var body: some View {
        ZStack {
            if statuses != nil {
                if !statuses!.isEmpty {
                    ScrollView(showsIndicators: false) {
                        if showHero {
                            Button {
                                withAnimation(.easeInOut) {
                                    showPicker.toggle()
                                }
                            } label: {
                                Image("HeroIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30)
                                    .padding(.bottom)
                            }
                        }
                        
                        ForEach(statuses!, id: \.id) { status in
                            LazyVStack(alignment: .leading, spacing: 2) {
                                CompactPostView(status: status)
                                    .onDisappear {
                                        guard statuses != nil else { return }
                                        lastSeen = statuses!.firstIndex(where: { $0.id == status.id })
                                    }
                            }
                        }
                    }
                    .refreshable {
                        if let client = accountManager.getClient() {
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
                    .padding(.top)
                    .background(Color.appBackground)
                } else {
                    ZStack {
                        Color.appBackground
                            .ignoresSafeArea()
                        
                        VStack {
                            Image("HeroIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50)
                                .padding(.bottom)
                            
                            ContentUnavailableView {
                                Text("timeline.empty")
                                    .bold()
                            } description: {
                                Text("timeline.empty.description")
                            }
                            .scrollDisabled(true)
                        }
                        .scrollDisabled(true)
                        .background(Color.appBackground)
                        .frame(height: 200)
                    }
                }
            } else {
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                        .onAppear {
                            if let client = accountManager.getClient() {
                                timelineModel.client = client
                                Task {
                                    statuses = await timelineModel.fetch(client: client)
                                }
                            }
                        }
                    
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
        }
        .background(Color.appBackground)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaPadding()
    }
}

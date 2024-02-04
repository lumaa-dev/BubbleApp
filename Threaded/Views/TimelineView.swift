//Made by Lumaa

import SwiftUI

struct TimelineView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @State var navigator: Navigator = Navigator()
    
    @State private var showPicker: Bool = false
    @State private var stringTimeline: String = "home"
    @State private var timeline: TimelineFilter = .home
    @State private var timelines: [TimelineFilter] = [.trending, .home]
    
    @State private var loadingStatuses: Bool = false
    @State private var statuses: [Status]?
    @State private var lastSeen: Int?
    
    @State var timelineModel: FetchTimeline // home timeline by default
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            if statuses != nil {
                if !statuses!.isEmpty {
                    ScrollView(showsIndicators: false) {
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
                        
//                        if showPicker {
//                            //TODO: Fix this
//                            
//                            MetaPicker(items: timelines.map { $0.rawValue }, selectedItem: $stringTimeline) { item in
//                                let title: String = timelines.filter{ $0.rawValue == item }.first?.localizedTitle() ?? "Unknown"
//                                Text("\(title)")
//                            }
//                                .padding(.bottom)
//                                .onChange(of: stringTimeline) { _, newTimeline in
//                                    let loc = timelines.filter{ $0.rawValue == newTimeline }.first?.localizedTitle()
//                                    switch (loc) {
//                                        case "home":
//                                            timeline = .home
//                                        case "trending":
//                                            timeline = .trending
//                                        default:
//                                            timeline = .home
//                                    }
//                                }
//                        }
                        
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
                    .withAppRouter(navigator)
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
        .environmentObject(navigator)
        .background(Color.appBackground)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaPadding()
    }
}

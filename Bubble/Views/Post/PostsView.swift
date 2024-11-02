//Made by Lumaa

import SwiftUI

struct PostsView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    //    @EnvironmentObject private var navigator: Navigator

    @State private var showPicker: Bool = false
    @State private var timelines: [TimelineFilter] = [.home, .trending, .local, .federated]

    @State private var loadingStatuses: Bool = false
    @State private var statuses: [Status]?
    @State private var lastSeen: Int?

    @State var filter: TimelineFilter
    @State var showHero: Bool = false
    @State var timelineModel: FetchTimeline // home timeline by default

    init(timelineModel: FetchTimeline, filter: TimelineFilter, showHero: Bool = false) {
        self.timelineModel = timelineModel
        self.filter = filter
        self.timelineModel.setTimelineFilter(filter)
        self.showHero = showHero
    }

    init(filter: TimelineFilter, showHero: Bool = false) {
        self.timelineModel = .init(client: AccountManager.shared.forceClient())
        self.filter = filter
        self.timelineModel.setTimelineFilter(filter)
        self.showHero = showHero
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

                        if showPicker {
                            picker
                        }

                        posts
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
//                    .padding(.top)
                    .background(Color.appBackground)
                } else {
                    emptyView
                }
            } else {
                loadingView
            }
        }
        .navigationTitle(filter.localizedTitle())
        .background(Color.appBackground)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    @ViewBuilder
    private var posts: some View {
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

    @ViewBuilder
    private var picker: some View {
        ViewThatFits {
            HStack {
                ForEach(timelines, id: \.self) { t in
                    Button {
                        Task {
                            await reloadTimeline(t)
                        }
                    } label: {
                        Text(t.localizedTitle())
                            .padding(.horizontal)
                    }
                    .buttonStyle(LargeButton(filled: t == filter, height: 7.5))
                    .disabled(t == filter)
                }
            }

            ScrollView(.horizontal) {
                HStack {
                    ForEach(timelines, id: \.self) { t in
                        Button {
                            Task {
                                await reloadTimeline(t)
                            }
                        } label: {
                            Text(t.localizedTitle())
                                .padding(.horizontal)
                        }
                        .buttonStyle(LargeButton(filled: t == filter, height: 7.5))
                        .disabled(t == filter)
                    }
                }
            }
            .padding(.vertical)
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private var emptyView: some View {
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

    @ViewBuilder
    private var loadingView: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
                .onAppear {
                    timelineModel.setTimelineFilter(filter)
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

    private func reloadTimeline(_ filter: TimelineFilter) async {
        guard let client = accountManager.getClient() else { return }
        statuses = nil
        self.filter = filter
        timelineModel.setTimelineFilter(filter)
        
        Task {
            loadingStatuses = true
            statuses = await timelineModel.fetch(client: client)
            lastSeen = nil
            loadingStatuses = false
        }
    }
}

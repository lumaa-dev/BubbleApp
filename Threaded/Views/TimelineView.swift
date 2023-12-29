//Made by Lumaa

import SwiftUI

struct TimelineView: View {
    @Environment(Client.self) private var client: Client
    
    @State private var navigator: Navigator = Navigator()
    @State private var statuses: [Status]?
    
    @State var timelineModel: FetchTimeline
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            if statuses != nil {
                ScrollView(showsIndicators: false) {
                    Image("HeroIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30)
                        .padding(.bottom)
                    
                    ForEach(statuses!, id: \.id) { status in
                        VStack(spacing: 2) {
                            CompactPostView(status: status, navigator: navigator)
                        }
                    }
                }
                .padding(.top)
                .background(Color.appBackground)
                .withAppRouter()
            } else {
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                        .onAppear {
                            Task {
                                statuses = try? await client.get(endpoint: Timelines.home(sinceId: nil, maxId: nil, minId: nil))
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

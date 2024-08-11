//Made by Lumaa

import SwiftUI

struct TabsView: View {
    @State var selectedTab: TabDestination = Navigator.shared.selectedTab

    var canTap: Binding<Bool> = .constant(true)

    var postButton: () -> Void = {}
    var tapAction: () -> Void = {}
    var retapAction: () -> Void = {}

    var body: some View {
        HStack(alignment: .center) {
            Button {
                guard canTap.wrappedValue else { return }

                if selectedTab == .timeline {
                    retapAction()
                } else {
                    selectedTab = .timeline
                    tapAction()
                }
            } label: {
                if selectedTab == .timeline {
                    Tabs.timeline.imageFill
                } else {
                    Tabs.timeline.image
                }
            }
            .disabled(!canTap.wrappedValue)
            .buttonStyle(NoTapAnimationStyle())
            
            Spacer()
            
            Button {
                guard canTap.wrappedValue else { return }

                if selectedTab == .search {
                    retapAction()
                } else {
                    selectedTab = .search
                    tapAction()
                }
            } label: {
                if selectedTab == .search {
                    Tabs.search.imageFill
                } else {
                    Tabs.search.image
                }
            }
            .disabled(!canTap.wrappedValue)
            .buttonStyle(NoTapAnimationStyle())
            
            Spacer()
            
            Button {
                guard canTap.wrappedValue else { return }

                postButton()
            } label: {
                Tabs.post.image
            }
            .disabled(!canTap.wrappedValue)
            .buttonStyle(NoTapAnimationStyle())
            
            Spacer()
            
            Button {
                guard canTap.wrappedValue else { return }

                if selectedTab == .activity {
                    retapAction()
                } else {
                    selectedTab = .activity
                    tapAction()
                }
            } label: {
                if selectedTab == .activity {
                    Tabs.activity.imageFill
                } else {
                    Tabs.activity.image
                }
            }
            .disabled(!canTap.wrappedValue)
            .buttonStyle(NoTapAnimationStyle())
            
            Spacer()
            
            Button {
                guard canTap.wrappedValue else { return }

                if selectedTab == .profile {
                    retapAction()
                } else {
                    selectedTab = .profile
                    tapAction()
                }
            } label: {
                if selectedTab == .profile {
                    Tabs.profile.imageFill
                } else {
                    Tabs.profile.image
                }
            }
            .disabled(!canTap.wrappedValue)
            .buttonStyle(NoTapAnimationStyle())
        }
        .padding(.horizontal, 30)
        .background(Color.appBackground)
        .onChange(of: selectedTab) { _, newValue in
            Navigator.shared.selectedTab = newValue
        }
    }
}

enum Tabs {
    case timeline
    case search
    case post
    case activity
    case profile
    
    @ViewBuilder
    var image: some View {
        switch self {
            case .timeline:
                Image(systemName: "house")
                    .tabBarify()
            case .search:
                Image(systemName: "magnifyingglass")
                    .tabBarify()
            case .post:
                Image(systemName: "square.and.pencil")
                    .tabBarify()
            case .activity:
                Image(systemName: "heart")
                    .tabBarify()
            case .profile:
                Image(systemName: "person")
                    .tabBarify()
                
        }
    }
    
    @ViewBuilder
    var imageFill: some View {
        switch self {
            case .timeline:
                Image(systemName: "house.fill")
                    .tabBarify(false)
            case .search:
                Image(systemName: "magnifyingglass")
                    .tabBarify(false)
            case .post:
                Image(systemName: "square.and.pencil")
                    .tabBarify(false)
            case .activity:
                Image(systemName: "heart.fill")
                    .tabBarify(false)
            case .profile:
                Image(systemName: "person.fill")
                    .tabBarify(false)
                
        }
    }
}

private extension Image {
    func tabBarify(_ neutral: Bool = true) -> some View {
        self
            .font(.title)
            .opacity(neutral ? 0.3 : 1)
    }
}

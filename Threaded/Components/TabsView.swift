//Made by Lumaa

import SwiftUI

struct TabsView: View {
    @State var navigator: Navigator
    
    var body: some View {
        HStack(alignment: .center) {
            Button {
                navigator.selectedTab = .timeline
            } label: {
                if navigator.selectedTab == .timeline {
                    Tabs.timeline.imageFill
                } else {
                    Tabs.timeline.image
                }
            }
            .buttonStyle(NoTapAnimationStyle())
            
            Spacer()
            
            Button {
                navigator.selectedTab = .search
            } label: {
                if navigator.selectedTab == .search {
                    Tabs.search.imageFill
                } else {
                    Tabs.search.image
                }
            }
            .buttonStyle(NoTapAnimationStyle())
            
            Spacer()
            
            Button {
                navigator.presentedSheet = .post
            } label: {
                Tabs.post.image
            }
            .buttonStyle(NoTapAnimationStyle())
            
            Spacer()
            
            Button {
                navigator.selectedTab = .activity
            } label: {
                if navigator.selectedTab == .activity {
                    Tabs.activity.imageFill
                } else {
                    Tabs.activity.image
                }
            }
            .buttonStyle(NoTapAnimationStyle())
            
            Spacer()
            
            Button {
                navigator.selectedTab = .profile
            } label: {
                if navigator.selectedTab == .profile {
                    Tabs.profile.imageFill
                } else {
                    Tabs.profile.image
                }
            }
            .buttonStyle(NoTapAnimationStyle())
        }
        .withSheets(sheetDestination: $navigator.presentedSheet)
        .padding(.horizontal, 30)
        .background(Color.appBackground)
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

extension Image {
    func tabBarify(_ neutral: Bool = true) -> some View {
        self
            .font(.title2)
            .opacity(neutral ? 0.3 : 1)
    }
}

#Preview {
    TabsView(navigator: Navigator())
        .previewLayout(.sizeThatFits)
}

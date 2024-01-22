//Made by Lumaa

import Foundation
import SwiftUI

@Observable
public class Navigator: ObservableObject {    
    public var path: [RouterDestination] = []
    public var presentedSheet: SheetDestination?
    public var selectedTab: TabDestination = .timeline
    
    public func navigate(to: RouterDestination) {
        path.append(to)
        print("appended view")
    }
}

public enum TabDestination: Identifiable {
    case timeline
    case search
    case activity
    case profile
    
    public var id: String {
        switch self {
            case .timeline:
                return "timeline"
            case .search:
                return "search"
            case .activity:
                return "activity"
            case .profile:
                return "profile"
        }
    }
}

public enum SheetDestination: Identifiable {
    case welcome
    case mastodonLogin(logged: Binding<Bool>)
    case post(content: String = "", replyId: String? = nil)
    case safari(url: URL)
    case shareImage(image: UIImage)
    
    public var id: String {
        switch self {
            case .welcome:
                return "welcome"
            case .mastodonLogin:
                return "login"
            case .post:
                return "post"
            case .safari:
                return "safari"
            case .shareImage:
                return "shareImage"
        }
    }
    
    public var isCover: Bool {
        switch self {
            case .welcome:
                return true
                
            case .mastodonLogin:
                return false
                
            case .post:
                return false
                
            case .safari:
                return false
                
            case .shareImage:
                return false
        }
    }
}

public enum RouterDestination: Hashable {
    case settings
    case privacy
    case appearence
    case account(acc: Account)
    case post(status: Status)
    case about
}

extension View {
    func withAppRouter(_ navigator: Navigator) -> some View {
        navigationDestination(for: RouterDestination.self) { destination in
            switch destination {
                case .settings:
                    SettingsView(navigator: navigator)
                case .privacy:
                    PrivacyView()
                case .appearence:
                    AppearenceView()
                case .account(let acc):
                    AccountView(account: acc)
                case .post(let status):
                    PostDetailsView(status: status)
                case .about:
                    AboutView()
            }
        }
    }
    
    func withSheets(sheetDestination: Binding<SheetDestination?>) -> some View {
        sheet(item: sheetDestination) { destination in
            viewRepresentation(destination: destination, isCover: false)
        }
    }
    
    func withCovers(sheetDestination: Binding<SheetDestination?>) -> some View {
        fullScreenCover(item: sheetDestination) { destination in
            viewRepresentation(destination: destination, isCover: true)
        }
    }
    
    private func viewRepresentation(destination: SheetDestination, isCover: Bool) -> some View {
        Group {
            if destination.isCover {
                switch destination {
                    case .welcome:
                        ConnectView()
                    default:
                        EmptyView()
                }
            } else {
                switch destination {
                    case .post(let content, let replyId):
                        NavigationStack {
                            PostingView(initialString: content, replyId: replyId)
                                .tint(Color(uiColor: UIColor.label))
                        }
                    case let .mastodonLogin(logged):
                        AddInstanceView(logged: logged)
                            .tint(Color.accentColor)
                    case let .safari(url):
                        SfSafariView(url: url)
                    case let .shareImage(image):
                        ShareSheet(image: image)
                    default:
                        EmptyView()
                }
            }
        }
    }
}

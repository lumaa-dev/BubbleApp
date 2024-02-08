//Made by Lumaa

import SwiftUI

struct SettingsView: View {
    @Environment(UniversalNavigator.self) private var uniNav: UniversalNavigator
    @State var navigator: Navigator
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            List {
                Section {
                    Button {
                        navigator.navigate(to: .about)
                    } label: {
                        Label("about", systemImage: "info.circle")
                    }
                    .listRowThreaded()
                    
//                    Button {
//                        sheet = .shop
//                    } label: {
//                        Label(String("Threaded+"), systemImage: "plus")
//                    }
//                    .listRowThreaded()
                    
                    Button {
                        navigator.navigate(to: .privacy)
                    } label: {
                        Label("setting.privacy", systemImage: "lock")
                    }
                    .listRowThreaded()
                    
                    Button {
                        navigator.navigate(to: .appearence)
                    } label: {
                        Label("setting.appearence", systemImage: "rectangle.3.group")
                    }
                    .listRowThreaded()
                    
                    Button {
                        AppAccount.clear()
                        navigator.path = []
                        navigator.selectedTab = .timeline
                        uniNav.presentedCover = .welcome
                    } label: {
                        Text("logout")
                            .foregroundStyle(.red)
                    }
                    .tint(Color.red)
                    .listRowThreaded()
                }
            }
            .withAppRouter(navigator)
            .listThreaded()
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView(navigator: .init())
}

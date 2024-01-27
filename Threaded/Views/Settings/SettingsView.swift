//Made by Lumaa

import SwiftUI

struct SettingsView: View {
    @State var navigator: Navigator
    @State private var sheet: SheetDestination?
    
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
                    
                    Button {
                        sheet = .shop
                    } label: {
                        Label(String("Threaded+"), systemImage: "plus")
                    }
                    .listRowThreaded()
                    
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
                        sheet = .welcome
                    } label: {
                        Text("logout")
                            .foregroundStyle(.red)
                    }
                    .tint(Color.red)
                    .listRowThreaded()
                }
            }
            .withAppRouter(navigator)
            .withCovers(sheetDestination: $sheet)
            .listThreaded()
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView(navigator: .init())
}

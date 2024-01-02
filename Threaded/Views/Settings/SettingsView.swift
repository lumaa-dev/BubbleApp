//Made by Lumaa

import SwiftUI

struct SettingsView: View {
    @State var navigator: Navigator
    @State private var sheet: SheetDestination?
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            List {
                Button {
                    navigator.navigate(to: .about)
                } label: {
                    Label("about", systemImage: "info.circle")
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.appBackground)
                
                Button {
                    navigator.navigate(to: .privacy)
                } label: {
                    Label("setting.privacy", systemImage: "lock")
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.appBackground)
                
                Button {
                    AppAccount.clear()
                    sheet = .welcome
                } label: {
                    Text("logout")
                        .foregroundStyle(.red)
                }
                .tint(Color.red)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.appBackground)
            }
            .withAppRouter(navigator)
            .withCovers(sheetDestination: $sheet)
            .scrollContentBackground(.hidden)
            .tint(Color.white)
            .background(Color.appBackground)
            .listStyle(.inset)
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView(navigator: .init())
}

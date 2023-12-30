//Made by Lumaa

import SwiftUI

struct SettingsView: View {
    @Environment(Navigator.self) private var navigator: Navigator
    @State private var sheet: SheetDestination?
    
    var body: some View {
        List {
            Button {
                navigator.navigate(to: .about)
            } label: {
                Label("about", systemImage: "info.circle")
            }
            .listRowSeparator(.hidden)
            
            Button {
                navigator.navigate(to: .privacy)
            } label: {
                Label("setting.privacy", systemImage: "lock")
            }
            .listRowSeparator(.hidden)
            
            Button {
                UserDefaults.standard.removeObject(forKey: AppAccount.saveKey)
                sheet = .welcome
            } label: {
                Text("logout")
                    .foregroundStyle(.red)
            }
            .tint(Color.red)
            .listRowSeparator(.visible, edges: .bottom)
        }
        .withCovers(sheetDestination: $sheet)
        .listStyle(.inset)
        .navigationTitle("settings")
    }
}

#Preview {
    SettingsView()
}

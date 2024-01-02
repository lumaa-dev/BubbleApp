//Made by Lumaa

import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            NavigationLink {
                aboutApp
            } label: {
                Text("about.app")
                    .tint(Color.blue)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.appBackground)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("about")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var aboutApp: some View {
        ScrollView {
            VStack (spacing: 15) {
                Text("about.app.details")
                    .multilineTextAlignment(.leading)
                Text("about.app.third-party")
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal)
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("about.app")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    AboutView()
}

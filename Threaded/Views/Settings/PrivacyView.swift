//Made by Lumaa

import SwiftUI
import Nuke

struct PrivacyView: View {
    @EnvironmentObject private var navigator: Navigator
    
    @State private var clearedCache: Bool = false
    
    var body: some View {
        List {
            //TODO: Visibilty, Blocklist & Mutelist
            
            HStack {
                Text("settings.privacy.clear-cache")
                
                Spacer()
                
                Button {
                    let cache = ImagePipeline.shared.cache
                    cache.removeAll()
                    withAnimation(.spring) {
                        clearedCache = true
                    }
                } label: {
                    Text(clearedCache ? "settings.privacy.cleared" : "settings.privacy.clear")
                }
                .buttonStyle(LargeButton(filled: true, filledColor: clearedCache ? Color.green : Color(uiColor: UIColor.label), height: 7.5))
                .disabled(clearedCache)
            }
            .listRowThreaded()
        }
        .listThreaded()
    }
}

#Preview {
    PrivacyView()
}

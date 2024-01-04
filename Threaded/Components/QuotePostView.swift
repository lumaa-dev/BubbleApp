//Made by Lumaa

import SwiftUI

struct QuotePostView: View {
    @Environment(Navigator.self) private var navigator: Navigator
    var status: Status
    
    var body: some View {
        //TODO: Fix profile picture and stats
        
        CompactPostView(status: status, navigator: navigator)
            .padding(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

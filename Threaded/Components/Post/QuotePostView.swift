//Made by Lumaa

import SwiftUI

struct QuotePostView: View {
    @Environment(Navigator.self) private var navigator: Navigator
    var status: Status
    
    var body: some View {
        CompactPostView(status: status, navigator: navigator, quoted: true)
            .frame(maxWidth: 250, maxHeight: 200)
            .padding(15)
            .padding([.horizontal], 20)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

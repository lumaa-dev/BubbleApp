//Made by Lumaa

import SwiftUI

struct QuotePostView: View {
    @EnvironmentObject private var navigator: Navigator
    var status: Status
    
    var body: some View {
        CompactPostView(status: status, quoted: true)
            .frame(maxWidth: 250, maxHeight: 200)
            .padding(7.5)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

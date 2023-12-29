//Made by Lumaa

import SwiftUI

struct OnlineImage: View {
    var url: URL
    
    var body: some View {
        AsyncImage(url: url) { element in
            element
                .resizable()
                .scaledToFit()
                .aspectRatio(1.0, contentMode: .fit)
        } placeholder: {
            Rectangle()
                .fill(Color.gray)
                .overlay {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
        }
    }
}

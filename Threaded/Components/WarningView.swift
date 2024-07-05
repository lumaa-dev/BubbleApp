//Made by Lumaa

import SwiftUI

struct WarningView: View {
    var description: LocalizedStringResource
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
                
                Text("warning.title")
                    .font(.title2.bold())
                    .lineLimit(1)
            }
            
            Text(description)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 5.0)
    }
}

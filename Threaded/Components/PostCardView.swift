//Made by Lumaa

import SwiftUI

struct PostCardView: View {
    var card: Card
    var inQuote: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            if card.image != nil {
                OnlineImage(url: card.image, size: inQuote ? 260 : 300, useNuke: false)
                    .frame(width: inQuote ? 250 : 300)
            }
                     
            VStack(alignment: .leading) {
                if let host = URL(string: card.url)?.host() {
                    Text(host)
                        .font(.footnote)
                        .foregroundStyle(Color.gray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .padding([.top], card.image == nil ? 10 : 0)
                }
                
                Text(card.title ?? "")
                    .font(.headline.bold())
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text(card.description ?? "")
                    .font(.footnote)
                    .foregroundStyle(Color.gray)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            .padding([.horizontal, .bottom], 10)
        }
        .frame(width: inQuote ? 200 : 250)
        .padding(.horizontal, 10)
        .clipShape(.rect(cornerRadius: 15))
        .fixedSize(horizontal: false, vertical: true)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            if UIApplication.shared.canOpenURL(URL(string: card.url)!) {
                UIApplication.shared.open(URL(string: card.url)!)
            }
        }
    }
}

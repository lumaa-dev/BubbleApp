//Made by Lumaa

import SwiftUI

struct PostCardView: View {
    @Environment(\.openURL) private var openURL
    
    var card: Card
    var inQuote: Bool = false
    var imaging: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            if card.image != nil {
                OnlineImage(url: card.image, size: inQuote ? 260 : 300, useNuke: imaging)
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
            .padding(card.authors.first?.account == nil ? [.horizontal, .bottom] : [.horizontal], 10)

            if let acc = card.authors.first?.account {
                Divider()
                    .frame(maxWidth: .infinity)

                HStack(alignment: .center) {
                    Label {
                        Text("status.card.author-\(acc.acct)")
                            .font(.caption)
                            .lineLimit(1)
                    } icon: {
                        ProfilePicture(url: acc.avatar, size: 30.0)
                    }
                    .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.horizontal, .bottom], 10)
                .onTapGesture {
                    Navigator.shared.navigate(to: .account(acc: acc))
                }
            }
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
            if let url = URL(string: card.url) {
                openURL(url)
            }
        }
    }
}

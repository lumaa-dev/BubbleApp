//Made by Lumaa

import SwiftUI

struct QuotePostView: View {
    @Environment(Navigator.self) private var navigator: Navigator
    var status: Status
    
    var body: some View {
        statusPost(status)
            .frame(width: 250)
            .padding(.horizontal, 10)
            .clipShape(.rect(cornerRadius: 15))
            .fixedSize(horizontal: false, vertical: true)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.gray.opacity(0.3), lineWidth: 1)
            )
            .onTapGesture {
                if UIApplication.shared.canOpenURL(URL(string: status.url ?? .fallbackUrl)!) {
                    UIApplication.shared.open(URL(string: status.url ?? .fallbackUrl)!)
                }
            }
    }
    
    @ViewBuilder
    func statusPost(_ status: AnyStatus) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // MARK: Profile picture
            if status.repliesCount > 0 {
                VStack {
                    profilePicture
                        .onTapGesture {
                            navigator.navigate(to: .account(acc: status.account))
                        }
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2.5)
                        .clipShape(.capsule)
                        .padding([.vertical], 5)
                    
                    Spacer()
                    
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(Color.gray.opacity(0.3))
                        .padding(.bottom, 2.5)
                }
            } else {
                profilePicture
                    .onTapGesture {
                        navigator.navigate(to: .account(acc: status.account))
                    }
            }
            
            VStack(alignment: .leading) {
                // MARK: Status main content
                VStack(alignment: .leading, spacing: 10) {
                    Text(status.account.username)
                        .multilineTextAlignment(.leading)
                        .bold()
                        .onTapGesture {
                            navigator.navigate(to: .account(acc: status.account))
                        }
                    
                    if !status.content.asRawText.isEmpty {
                        TextEmoji(status.content, emojis: status.emojis, language: status.language)
                            .multilineTextAlignment(.leading)
                            .frame(width: 250, alignment: .topLeading)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.callout)
                    }
                    
                    if status.card != nil {
                        PostCardView(card: status.card!, inQuote: true)
                    }
                }
                .padding(.top)
                
                // MARK: Status stats
                stats
                    .padding(.top, 5)
                    .padding(.bottom, status.repliesCount > 0 || status.favouritesCount > 0 ? 10 : 0)
            }
        }
    }
    
    var profilePicture: some View {
        OnlineImage(url: status.account.avatar, size: 40, useNuke: true)
            .frame(width: 25, height: 25)
            .padding(.horizontal)
            .clipShape(.circle)
    }
    
    var stats: some View {
        //TODO: Put this in its own view (maybe?)
        HStack {
            if status.repliesCount > 0 {
                Text("status.replies-\(status.repliesCount)")
                    .monospacedDigit()
                    .foregroundStyle(.gray)
            }
            
            if status.repliesCount > 0 && status.favouritesCount > 0 {
                Text("•")
                    .foregroundStyle(.gray)
            }
            
            if status.favouritesCount > 0 {
                Text("status.favourites-\(status.favouritesCount)")
                    .monospacedDigit()
                    .foregroundStyle(.gray)
            }
        }
    }
}

private extension String {
    static let fallbackUrl = "https://joinmastodon.org/"
}

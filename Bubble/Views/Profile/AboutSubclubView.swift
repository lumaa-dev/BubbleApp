// Made by Lumaa

import SwiftUI

struct AboutSubclubView: View {
    @Environment(AppDelegate.self) private var appDelegate: AppDelegate
    @Environment(\.openURL) private var openURL: OpenURLAction
    @Environment(\.dismiss) private var dismiss: DismissAction

    var body: some View {
        ScrollView {
            Label {
                Text(String("sub.club"))
                    .font(.subClub(size: CGFloat.getFontSize(from: .title1)))
                    .foregroundStyle(Color.subClub)
            } icon: {
                Image("SubClubMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }
            .padding(.vertical)

            Text("info.subclub.description")
                .multilineTextAlignment(.leading)
                .frame(width: appDelegate.windowWidth - 50, alignment: .leading)
                .padding()
                .background(Material.bar.opacity(0.5))
                .clipShape(.rect(cornerRadius: 7.5))

            Text("info.subclub.collaboration")
                .multilineTextAlignment(.leading)
                .frame(width: appDelegate.windowWidth - 50, alignment: .leading)
                .padding()
                .background(Material.bar.opacity(0.5))
                .clipShape(.rect(cornerRadius: 7.5))

            AccountRow(acct: "subclub@mastodon.social") {
                Text("accounts.subclub")
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .font(Font.subClub(size: .getFontSize(from: .headline)))
                    .foregroundStyle(Color.subClub)
            }
            .frame(width: appDelegate.windowWidth - 50)
            .padding()
            .background(Material.bar.opacity(0.5))
            .clipShape(.rect(cornerRadius: 7.5))


            Button {
                dismiss()
                openURL(URL(string: "https://sub.club/?utm_source=BubbleApp")!)
            } label: {
                HStack {
                    Text("learn.subclub")
                    Image(systemName: "arrow.up.forward.square")
                }
                .frame(width: appDelegate.windowWidth - 50)
            }
            .buttonStyle(LargeButton(filled: true, filledColor: Color.subClub))
        }
        .frame(width: appDelegate.windowWidth)
        .presentationDetents([.medium])
        .clearSheetBackground()
        .background(Material.ultraThin)
    }
}

extension Font {
    static func subClub(size: CGFloat) -> Font { Font.custom("PolySans-BulkyWide", size: size) }
}

#Preview {
    AccountView(account: .placeholder())
        .sheet(isPresented: .constant(true)) {
            AboutSubclubView()
        }
        .environmentObject(UserPreferences())
        .environment(AppDelegate())
        .environment(AccountManager())
        .environment(Navigator())
        .environment(UniversalNavigator())
}

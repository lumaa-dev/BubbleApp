//Made by Lumaa

import SwiftUI

struct ConnectView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var sheet: SheetDestination?
    @State private var logged: Bool = false
    
    var body: some View {
        VStack {
            Text("login.title")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 30) {
                Button {
                    sheet = .mastodonLogin(logged: $logged)
                } label: {
                    mastodon
                }
                .buttonStyle(LargeButton())
                
                Button {
                    print("go directly")
                } label: {
                    noAccount
                }
                .buttonStyle(LargeButton())
            }
            .padding(.vertical, 100)
        }
        .withSheets(sheetDestination: $sheet)
        .safeAreaPadding()
        .onChange(of: logged) { _, newValue in
            if newValue == true {
                dismiss()
            }
        }
    }
    
    var mastodon: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("login.mastodon")
                Text("login.mastodon.footer")
                    .multilineTextAlignment(.leading)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Image("MastodonMark")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        }
    }
    
    var noAccount: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("login.no-account")
                Text("login.no-account.footer")
                    .multilineTextAlignment(.leading)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Image(systemName: "person.crop.circle.dashed")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        }
    }
}

#Preview {
    ConnectView()
}

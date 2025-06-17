// Made by Lumaa

import SwiftUI

struct PlusNecessaryView: View {
    var lockedFeature: AppInfo.Feature? = nil

    init(_ lockedFeature: AppInfo.Feature? = nil) {
        self.lockedFeature = lockedFeature
    }

    var body: some View {
        VStack(spacing: 7.5) {
            if let feature = lockedFeature {
                HStack {
                    Text("shop.bubble-plus.with")
                        .foregroundStyle(Color.black)
                        .font(.callout.width(.expanded).weight(.bold))

                    Image("HeroPlus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .environment(\.colorScheme, ColorScheme.light)
                        .padding(.trailing, 7.5)
                }
                .padding(7.5)
                .background(Color.white)
                .clipShape(Capsule())

                Image(systemName: feature.details.systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .padding(.vertical)

                Text(feature.details.title)
                    .font(.title2.bold())
                    .lineLimit(1)

                Text(feature.details.description)
                    .foregroundStyle(Color.gray)
                    .font(.callout)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
            } else {
                Image("HeroPlus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .padding(.vertical)

                Text("shop.bubble-plus.required")
                    .font(.title2.bold())
                    .lineLimit(1)

                Text("shop.bubble-plus.required.description")
                    .foregroundStyle(Color.gray)
                    .font(.callout)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
            }

            Button {
                Navigator.shared.presentedSheet = nil
                Navigator.shared.presentedCover = .shop
            } label: {
                Label {
                    Text("shop.bubble-plus.learn")
                } icon: {
                    Image("HeroPlus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .environment(\.colorScheme, ColorScheme.light)
                }
            }
            .buttonStyle(LargeButton(filled: true, height: 7.5))
            .padding(.vertical, 27.5)
        }
        .background(Color.appBackground)
        .padding()
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(35.0)
        .presentationBackground(Color.appBackground)
    }
}

#Preview {
    PlusNecessaryView()
}

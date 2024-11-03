//Made by Lumaa

import SwiftUI

struct UpdateView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(alignment: .center) {
                Text("update.title")
                    .font(.title.bold())
                    .padding(.top, 50)
                Text("about.version-\(AppInfo.appVersion)")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                
                Spacer()
                
                features
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("update.hide")
                        .frame(minWidth: 250)
                }
                .buttonStyle(LargeButton(filled: true))

                Spacer()
            }
        }
    }
    
    var features: some View {
        VStack(spacing: 60) {
            newFeature(systemImage: "figure.child.and.lock.fill", title: "Follow request", text: "A proper follow request button is available on private accounts")

            newFeature(imageName: "SubClubMark", title: "sub.club", text: "A full sub.club integration was made in collaboration with them! Thank you!")

            newFeature(systemImage: "decrease.quotelevel", title: "Post overhaul", text: "Posts and replies are looking fancier than ever before!")
        }
        .frame(height: 500)
    }

    @ViewBuilder
    private func newFeature(systemImage: String, title: String, text: String) -> some View {
        ViewThatFits {
            HStack(alignment: .center) {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(Color(uiColor: UIColor.label))
                
                Spacer()
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .bold()
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    Text(text)
                        .foregroundStyle(Color(uiColor: UIColor.label).opacity(0.7))
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                }
                
                Spacer()
            }
            .frame(width: 330)
            
            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                
                Text(text)
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func newFeature(imageName: String, title: String, text: String) -> some View {
        ViewThatFits {
            HStack(alignment: .center) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(Color(uiColor: UIColor.label))
                
                Spacer()
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .bold()
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    Text(text)
                        .foregroundStyle(Color(uiColor: UIColor.label).opacity(0.7))
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                }
                
                Spacer()
            }
            .frame(width: 330)
            
            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                
                Text(text)
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func newFeature(_ feature: AppInfo.Feature) -> some View {
        self.newFeature(
            systemImage: feature.details.systemImage,
            title: feature.details.title.toString(),
            text: feature.details.description.toString()
        )
    }
}

#Preview {
    Text(String("UpdateView"))
        .sheet(isPresented: .constant(true)) {
            UpdateView()
        }
}

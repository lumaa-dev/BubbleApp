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
            newFeature(image: Image("HeroIcon"), title: "New Bubble", text: "Bubble receives a brand new look, as well as iOS 26's Liquid Glass.")

            newFeature(image: Image(systemName: "apple.intelligence"), title: "(SOON) Less thinking for more", text: "Apple Intelligence can help you write and reply to posts")

            newFeature(image: Image(systemName: "beziercurve"), title: "Microdata Refinement", text: "Bubble has been largely optimized so that it runs smoother than ever")
        }
        .frame(height: 500)
    }

    @ViewBuilder
    private func newFeature(image: Image, title: String, text: String) -> some View {
        ViewThatFits {
            HStack(alignment: .center) {
                image
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
            image: Image(systemName: feature.details.systemImage),
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

//Made by Lumaa

import SwiftUI
import TipKit

struct HeadlineTipViewStyle: TipViewStyle {
    var headlineType: HeadlineType = .tip
    
    func makeBody(configuration: TipViewStyle.Configuration) -> some View {
        VStack(alignment: .leading) {
            if headlineType != .none {
                HStack {
                    Text(String(localized: LocalizedStringResource(stringLiteral: headlineType.rawValue)).uppercased())
                        .font(.headline.smallCaps())
                        .foregroundStyle(Color.gray)
                    
                    Spacer()
                    
                    Button(action: { configuration.tip.invalidate(reason: .tipClosed) }) {
                        Image(systemName: "xmark")
                            .scaledToFit()
                    }
                }
                
                Divider()
                    .frame(height: 1.0)
            }
            
            
            HStack(alignment: .top) {
                configuration.image?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48.0, height: 48.0)
                
                
                VStack(alignment: .leading, spacing: 8.0) {
                    configuration.title?.font(.headline)
                    configuration.message?.font(.subheadline)
                    
                    
                    ForEach(configuration.actions) { action in
                        Button(action: action.handler) {
                            action.label().foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.horizontal, 5)
            }
        }
        .padding()
    }
    
    public enum HeadlineType: String {
        case tip = "tip.headline.tip" // tip
        case new = "tip.headline.new" // new
        case update = "tip.headline.update" // updated
        case meta = "tip.headline.meta" // just like meta
        case none = ""
    }
}

extension View {
    func listThreaded(tint: Color = Color(uiColor: UIColor.label)) -> some View {
        self
            .scrollContentBackground(.hidden)
            .tint(tint)
            .background(Color.appBackground)
            .listStyle(.inset)
    }
    func listRowThreaded() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowBackground(Color.appBackground)
            .tint(Color.blue)
    }
}

//Made by Lumaa

import SwiftUI

struct LargeButton: ButtonStyle {
    var filled: Bool = false
    var height: CGFloat? = nil
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal)
            .padding(.vertical, height)
            .background {
                if filled {
                    Color(uiColor: UIColor.label)
                }
            }
            .foregroundStyle(filled ? Color(uiColor: UIColor.systemBackground) : Color(uiColor: UIColor.label))
            .bold(filled)
            .clipShape(.rect(cornerRadius: 15))
            .opacity(configuration.isPressed ? 0.3 : 1)
            .overlay {
                if !filled {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(uiColor: UIColor.tertiaryLabel))
                        .opacity(configuration.isPressed ? 0.3 : 1)
                }
            }
    }
}

struct NoTapAnimationStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .onTapGesture(perform: configuration.trigger)
    }
}

#Preview {
    Button {} label: {
        Text("Hello world")
    }
    .buttonStyle(NoTapAnimationStyle())
}

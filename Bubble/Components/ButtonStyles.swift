//Made by Lumaa

import SwiftUI

struct LargeButton: ButtonStyle {
    var filled: Bool = false
    var filledColor: Color = Color(uiColor: UIColor.label)
    var height: CGFloat? = nil
    var disabled: Bool = false
    
    private var fillColor: Color {
        if disabled {
            Color.gray
        } else {
            filledColor
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal)
            .padding(.vertical, height)
            .background {
                if filled {
                    fillColor
                }
            }
            .foregroundStyle(filled ? Color(uiColor: UIColor.systemBackground) : Color(uiColor: UIColor.label))
            .bold(filled)
            .clipShape(.capsule)
            .glassEffect(.regular.interactive().tint(filled ? filledColor : Color.clear), in: .capsule, isEnabled: !disabled)
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
        Text(String("Hello world"))
    }
    .buttonStyle(NoTapAnimationStyle())
}

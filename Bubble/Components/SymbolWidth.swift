//Made by Lumaa

import Foundation
import SwiftUI

struct SymbolWidthPreferenceKey: PreferenceKey {
    static var defaultValue: Double = 0
    
    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = max(value, nextValue())
    }
}

struct SymbolWidthModifier: ViewModifier {
    @Binding var width: Double
    
    func body(content: Content) -> some View {
        content
            .background(GeometryReader { geo in
                Color
                    .clear
                    .preference(key: SymbolWidthPreferenceKey.self, value: geo.size.width)
            })
    }
}

extension Image {
    func sync(with width: Binding<Double>) -> some View {
        modifier(SymbolWidthModifier(width: width))
    }
}

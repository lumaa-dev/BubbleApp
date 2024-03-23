//Made by Lumaa

import SwiftUI

struct ComingSoonView: View {
    init() {}
    
    @State private var spin: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 5) {
            Text(String("👀"))
                .font(.system(size: 62))
                .padding()
                .background(Color.gray.opacity(0.3))
                .clipShape(Circle())
                .tapToSpin(spin: $spin)
            
            Text("coming-soon")
                .font(.title.bold())
        }
    }
}

extension View {
    func tapToSpin(spin: Binding<CGFloat>, defaultValue: CGFloat = 0) -> some View {
        self
            .rotation3DEffect(.degrees(spin.wrappedValue), axis: (x: 0, y: 1, z: 0))
            .onTapGesture {
                withAnimation(.spring.speed(0.8)) {
                    spin.wrappedValue = 360
                }
                spin.wrappedValue = defaultValue
            }
    }
}

#Preview {
    ComingSoonView()
}

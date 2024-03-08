//Made by Lumaa

import SwiftUI

struct ComingSoonView: View {
    @State private var spin: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 5) {
            Text(String("👀"))
                .font(.system(size: 62))
                .rotation3DEffect(.degrees(spin), axis: (x: 0, y: 1, z: 0))
                .onTapGesture {
                    withAnimation(.spring.speed(0.8)) {
                        spin = 360
                    }
                    spin = 0
                }
            
            Text("coming-soon")
                .font(.title.bold())
        }
    }
}

#Preview {
    ComingSoonView()
}

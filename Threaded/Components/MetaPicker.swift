//Made by Lumaa

import SwiftUI

//TODO: Changes this for ONLY timeline picker

struct MetaPicker<Content : View>: View {
    @Namespace private var metaPicker
    @Namespace private var selectBar
    
    var items: [String]
    @Binding var selectedItem: String
    
    @ViewBuilder let content: (_ item: String) -> Content
    
    var body: some View {
        HStack {
            ForEach(items, id: \.self) { item in
                GeometryReader { geo in
                    let size = geo.size
                    VStack {
                        content(item)
                            .tag(item)
                            .foregroundStyle(item == selectedItem ? Color.white : Color.gray.opacity(0.3))
                        
                        if item == selectedItem {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: size.width, height: 2)
                                .matchedGeometryEffect(id: selectBar, in: metaPicker)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: size.width, height: 2)
                        }
                        
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring) {
                            selectedItem = item
                        }
                    }
                    
                    if items.last != item {
                        Spacer()
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

//Made by Lumaa

import SwiftUI
import StoreKit

struct ShopView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ProductView(id: "fr.lumaa.Threaded.plus") {
                VStack {
                    Text(String("Threaded+")) // Force the name as untranslatable
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text("shop.threaded-plus.description")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .ignoresSafeArea()
                .background(Color.yellow.gradient)
            }
            .productViewStyle(.large)
            .storeButton(.visible, for: .redeemCode)
            .navigationTitle(String(""))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("shop.cancel")
                    }
                }
            }
        }
    }
}

#Preview {
    ShopView()
}

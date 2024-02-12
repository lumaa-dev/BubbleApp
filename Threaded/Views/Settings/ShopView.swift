//Made by Lumaa

import SwiftUI
import StoreKit

struct ShopView: View {
    @Environment(AppDelegate.self) private var delegate: AppDelegate
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSub: Bool = false
    @State private var showLifetime: Bool = false
    
    var body: some View {
        VStack {
            Image("HeroPlus")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(.vertical)
            
            Spacer()
            
            VStack(spacing: 20) {
                Button {
                    showSub.toggle()
                } label: {
                    Text("shop.threaded-plus.subscription")
                }
                .buttonStyle(LargeButton(filled: true))
                .overlay(alignment: .topTrailing) {
                    Text("shop.best")
                        .foregroundStyle(Color.white)
                        .font(.caption.smallCaps())
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                        .padding(10)
                        .background(Capsule().fill(Color.red))
                        .offset(x: 20.0, y: -25.0)
                        .rotationEffect(.degrees(25.0))
                }
                
                Button {
                    showLifetime.toggle()
                } label: {
                    Text("shop.threaded-plus.lifetime")
                }
                .buttonStyle(LargeButton(filled: false))
                
                Button {
                    dismiss()
                } label: {
                    Text("shop.threaded-plus.dismiss")
                }
                .buttonStyle(.borderless)
                .padding(.top, 50)
            }
            .padding(.vertical)
        }
        .frame(width: delegate.windowWidth)
        .background(Color.appBackground)
        .sheet(isPresented: $showSub) {
            ShopView.SubView()
        }
        .sheet(isPresented: $showLifetime) {
            ShopView.LifetimeView()
        }
    }
}

extension ShopView {
    private struct SubView: View {
        var body: some View {
            NavigationStack {
                SubscriptionStoreView(productIDs:  ["fr.lumaa.Threaded.Plus.monthly", "fr.lumaa.ThreadedPlus.yearly"]) {
                    VStack {
                        Spacer()
                        
                        Image("HeroPlus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                        
                        Spacer()
                        
                        Text(String("Threaded+")) // Force the name as untranslatable
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        Text("shop.threaded-plus.subscription.description")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                }
                .background(Color.appBackground)
                .productViewStyle(.large)
                .storeButton(.visible, for: .redeemCode)
                .subscriptionStoreControlStyle(.prominentPicker)
                .subscriptionStoreControlBackground(Color.appBackground)
                .subscriptionStorePolicyDestination(url: URL(string: "https://apps.lumaa.fr/legal/privacy")!, for: .privacyPolicy)
                .subscriptionStorePolicyDestination(for: .termsOfService) {
                    ZStack {
                        Color.appBackground
                            .ignoresSafeArea()
                        
                        Text("tos.description")
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .padding(.horizontal)
                    }
                    .environment(\.colorScheme, ColorScheme.dark)
                }
                .navigationTitle(String("Subscription"))
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .tint(Color.white)
            }
            .environment(\.colorScheme, ColorScheme.dark)
        }
    }
    
    private struct LifetimeView: View {
        var body: some View {
            VStack {
                Text("shop.threaded-plus.lifetime.header")
                    .font(.title.bold())
                    .fontWidth(.expanded)
                
                ProductView(id: "fr.lumaa.ThreadedPlus.lifetime", prefersPromotionalIcon: true) {
                    ZStack {
                        Color.appBackground
                        
                        Image("HeroPlus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 25.0))
                    .environment(\.colorScheme, ColorScheme.dark)
                }
                .productViewStyle(.large)
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ShopView()
}

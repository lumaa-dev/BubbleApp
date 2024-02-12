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
            
            features
                .padding(.bottom)
            
            Spacer()
            
            VStack(spacing: 20) {
                Button {
                    showSub.toggle()
                } label: {
                    Text("shop.threaded-plus.subscription")
                }
                .buttonStyle(LargeButton(filled: true, disabled: true))
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
                .disabled(true)
                
                Button {
                    showLifetime.toggle()
                } label: {
                    Text("shop.threaded-plus.lifetime")
                }
                .buttonStyle(LargeButton(filled: false, disabled: true))
                .disabled(true)
                
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
        .navigationTitle(Text(String("Threaded+")))
        .sheet(isPresented: $showSub) {
            ShopView.SubView()
        }
        .sheet(isPresented: $showLifetime) {
            ShopView.LifetimeView()
        }
    }
    
    var features: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 25) {
                Text("shop.features")
                    .font(.title.bold())
                    .scrollTransition { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0)
                            .blur(radius: phase.isIdentity ? 0 : 5)
                            .offset(y: phase.isIdentity ? 0 : -15)
                    }
                
                feature("shop.features.drafts", description: "shop.features.drafts.description", systemImage: "pencil.and.outline")
                
                feature("shop.features.analytics", description: "shop.features.analytics.description", systemImage: "chart.line.uptrend.xyaxis.circle")
                
                feature("shop.features.content-filter", description: "shop.features.content-filter.description", systemImage: "wand.and.stars")
                
                feature("shop.features.download-atchmnt", description: "shop.features.download-atchmnt.description", systemImage: "photo.badge.arrow.down")
                
                feature("shop.features.vip", description: "shop.features.vip.description", systemImage: "crown")
            }
            .frame(width: delegate.windowWidth)
        }
        .scrollIndicatorsFlash(onAppear: true)
        .scrollClipDisabled()
    }
    
    @ViewBuilder
    private func feature(_ title: LocalizedStringKey, description: LocalizedStringKey = LocalizedStringKey(stringLiteral: ""), systemImage: String) -> some View {
        HStack(alignment: .center) {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                Text(description)
                    .font(.callout)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.leading, 20)
        .frame(width: delegate.windowWidth - 30)
        .padding(.vertical)
        .background(Color.gray.opacity(0.2))
        .clipShape(.capsule)
        .scrollTransition { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0)
                .scaleEffect(x: phase.isIdentity ? 1 : 0.5, y: phase.isIdentity ? 1 : 0.75, anchor: .center)
                .blur(radius: phase.isIdentity ? 0 : 10)
                .offset(y: phase.isIdentity ? 0 : 10)
        }
    }
}

extension ShopView {
    struct SubView: View {
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
    
    struct LifetimeView: View {
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
        .environment(AppDelegate())
//        .environment(\.locale, Locale(identifier: "en-us"))
}

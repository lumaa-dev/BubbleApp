//Made by Lumaa

import SwiftUI

struct IconView: View {
    var body: some View {
        List {
            ForEach(AppIcons.allCases, id: \.self) { icon in
                Button {
                    HapticManager.playHaptics(haptics: Haptic.tap)
                    changeAppIcon(to: icon.assetName)
                } label: {
                    HStack {
                        Image(icon.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 17.5))
                        
                        Text(icon.displayName)
                            .font(.title2)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle(Text("setting.app-icon"))
        .navigationBarTitleDisplayMode(.inline)
        .listThreaded()
    }
    
    private func changeAppIcon(to iconName: String) {
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                HapticManager.playHaptics(haptics: Haptic.error)
                print("Error setting alternate icon \(error.localizedDescription)")
            }
        }
    }
}

private enum AppIcons: CaseIterable {
    case `default`
    case purple
    case blue
    case twitter
    case pride
    case async
    case brat
    case artisticly
    
    var assetName: String {
        switch self {
            case .default:
                "DefaultIcon"
            case .purple:
                "PurpleIcon"
            case .blue:
                "BlueIcon"
            case .twitter:
                "TwitterIcon"
            case .pride:
                "PrideIcon"
            case .async:
                "AsyncIcon"
            case .brat:
                "BratIcon"
            case .artisticly:
                "ArtisticlyIcon"
            default:
                "DefaultIcon"
        }
    }
    
    var displayName: String {
        switch self {
            case .default:
                String(localized: "setting.app-icon.default")
            case .purple:
                String(localized: "setting.app-icon.purple")
            case .blue:
                String(localized: "setting.app-icon.blue")
            case .twitter:
                "Twitter"
            case .pride:
                String(localized: "setting.app-icon.pride")
            case .async:
                "A-Sync"
            case .brat:
                "BRAT - Charli XCX"
            case .artisticly:
                "Artisticly"
            default:
                String(localized: "setting.app-icon.unknown")
        }
    }
}

#Preview {
    IconView()
}

//Made by Lumaa

import SwiftUI

struct ProfilePicture: View {
    @Environment(UserPreferences.self) private var pref
    var url: URL
    var cornerRadius: CGFloat {
        return pref.profilePictureShape == .circle ? (50 / 2) : 15.0
    }
    
    init(url: URL) {
        self.url = url
    }
    
    init(url: String) {
        self.url = .init(string: url)!
    }
    
    var body: some View {
        OnlineImage(url: url, size: 50, useNuke: true)
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

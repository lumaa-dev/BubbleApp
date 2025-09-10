// Made by Lumaa

import SwiftUI

enum PostGeneration: Int, CaseIterable, Equatable, Identifiable {
    case enthusiasm = 0
    case serious = 1
    case promotional = 2
    case smartReply = 3

    var label: some View {
        switch self {
            case .enthusiasm:
                Label("ai.enthusiasm", systemImage: "camera.macro")
            case .serious:
                Label("ai.serious", systemImage: "suitcase")
            case .promotional:
                Label("ai.promotional", systemImage: "eurosign.bank.building")
            case .smartReply:
                Label("ai.smart-reply", image: "SmartReply")
        }
    }

    func prompt(context: String) -> String {
        switch self {
            case .enthusiasm:
                """
                Rewrite a more enthusiastic social media post from the following text:
                "\(context)"
                """
            case .serious:
                """
                Rewrite this social media post with a very serious tone:
                "\(context)"
                """
            case .promotional:
                """
                Rewrite this social media post to promote something the user might've made or discovered, keep it serious and corporate:
                "\(context)"
                """
            case .smartReply:
                """
                Write a short, thoughtful, and respectful reply/response to this social media post. Avoid taking strong political stances. If the social media is aggressive or controversial, respond calmly without humor. Be appropriate for a public conversation.
                
                The social media post:
                "\(context)"
                """
        }
    }

    var temperature: Double {
        switch self {
            case .enthusiasm:
                1.8
            case .promotional:
                0.5
            case .serious, .smartReply:
                0.3
        }
    }

    var id: Int {
        self.rawValue
    }
}

// Made by Lumaa

import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct CreatePostControl: ControlWidget {
    let kind: String = "CreatePostControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: OpenComposerIntent()) {
                Label("control.open.composer", systemImage: "square.and.pencil")
            }
        }
        .displayName("control.open.composer")
        .description("control.open.composer.description")
    }
}

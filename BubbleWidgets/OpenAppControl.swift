// Made by Lumaa


// Made by Lumaa

import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct OpenAppControl: ControlWidget {
    let kind: String = "CreateAppControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: OpenAppIntent(tab: TabDestination.timeline)) {
                Label("control.open.app", image: "hero.pen")
            }
        }
        .displayName("control.open.app")
        .description("control.open.app.description")
    }
}

//Made by Lumaa

import WidgetKit
import SwiftUI
import UIKit

@main
struct BubbleWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FollowCountWidget()
        FollowGoalWidget()
        CreatePostWidget()

        if #available(iOS 18.0, *) {
            CreatePostControl()
        }
    }
}

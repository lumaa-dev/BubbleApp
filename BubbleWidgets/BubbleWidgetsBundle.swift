//Made by Lumaa

import WidgetKit
import SwiftUI
import UIKit

@main
struct BubbleWidgetsBundle: WidgetBundle {
    var body: some Widget {
        return NewBundle
    }

    @available(iOS 18.0, *)
    @WidgetBundleBuilder
    private var NewBundle: some Widget {
        FollowCountWidget()
        FollowGoalWidget()
        CreatePostWidget()

        // iOS 18
        OpenAppControl()
        CreatePostControl()
    }
}



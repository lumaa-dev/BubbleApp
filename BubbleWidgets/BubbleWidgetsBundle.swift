//Made by Lumaa

import WidgetKit
import SwiftUI
import UIKit

@main
struct BubbleWidgetsBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOSApplicationExtension 18.0, *) {
            return NewBundle
        } else {
            return PrevBundle
        }
    }

    @available(iOS 18.0, *)
    @WidgetBundleBuilder
    private var NewBundle: some Widget {
        FollowCountWidget()
        FollowGoalWidget()
        CreatePostWidget()

        // iOS 18
        CreatePostControl()
    }

    @WidgetBundleBuilder
    private var PrevBundle: some Widget {
        FollowCountWidget()
        FollowGoalWidget()
        CreatePostWidget()
    }
}



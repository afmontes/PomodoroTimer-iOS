import WidgetKit
import SwiftUI

@main
struct PomodoroWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Regular widget if needed
        // PomodoroWidget()
        
        // Live Activity widget
        if #available(iOS 16.1, *) {
            PomodoroWidgetLiveActivity()
        }
    }
}
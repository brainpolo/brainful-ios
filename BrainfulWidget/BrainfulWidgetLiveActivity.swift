//
//  BrainfulWidgetLiveActivity.swift
//  BrainfulWidget
//
//  Created by Aditya STANDARD on 23/03/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BrainfulWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct BrainfulWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BrainfulWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension BrainfulWidgetAttributes {
    fileprivate static var preview: BrainfulWidgetAttributes {
        BrainfulWidgetAttributes(name: "World")
    }
}

extension BrainfulWidgetAttributes.ContentState {
    fileprivate static var smiley: BrainfulWidgetAttributes.ContentState {
        BrainfulWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BrainfulWidgetAttributes.ContentState {
         BrainfulWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: BrainfulWidgetAttributes.preview) {
   BrainfulWidgetLiveActivity()
} contentStates: {
    BrainfulWidgetAttributes.ContentState.smiley
    BrainfulWidgetAttributes.ContentState.starEyes
}

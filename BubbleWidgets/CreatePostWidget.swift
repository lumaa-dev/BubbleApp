// Made by Lumaa

import SwiftUI
import WidgetKit

struct CreatePostWidget: Widget {
    let kind: String = "CreatePostWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            CreatePostWidget.WidgetView()
        }
        .configurationDisplayName(LocalizedStringKey("widget.open.composer"))
        .description(LocalizedStringKey("widget.open.composer"))
        .supportedFamilies([.systemSmall])
        .disfavoredLocations(
            [.standBy, .iPhoneWidgetsOnMac],
            for: [.systemSmall]
        )
    }

    struct WidgetView: View {
        @Environment(\.widgetFamily) private var family: WidgetFamily
        @Environment(\.colorScheme) private var colorScheme: ColorScheme

        var body: some View {
            ZStack {
                if family == .systemSmall {
                    Button(intent: OpenComposerIntent()) {
                        Text("status.posting.placeholder")
                            .foregroundStyle(Color.gray)
                            .font(.callout)
                            .frame(width: 110, height: 110, alignment: .topLeading)
                            .padding(9.0)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }
            }
            .containerBackground(Color.appBackground, for: .widget)
        }
    }

    struct Provider: TimelineProvider {
        func getSnapshot(
            in context: Context,
            completion: @escaping @Sendable (CreatePostWidget.Entry) -> Void
        ) {
            completion(.init(date: .now))
        }

        func getTimeline(
            in context: Context,
            completion: @escaping (Timeline<CreatePostWidget.Entry>) -> Void
        ) {
            var entries: [CreatePostWidget.Entry] = []

            // Generate a timeline consisting of two entries an hour apart, starting from the current date.
            let currentDate = Date()
            for hourOffset in 0 ..< 2 {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                let entry = CreatePostWidget.Entry(date: entryDate)
                entries.append(entry)
            }

            completion(Timeline(entries: entries, policy: .atEnd))
        }

        func placeholder(in context: Context) -> CreatePostWidget.Entry {
            return .init(date: .now)
        }
    }

    struct Entry: TimelineEntry {
        let date: Date
    }
}

#Preview(as: .systemSmall) {
    CreatePostWidget()
} timeline: {
    CreatePostWidget.Entry(date: .now)
}

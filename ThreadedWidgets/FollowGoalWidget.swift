//Made by Lumaa

import WidgetKit
import SwiftUI
import SwiftData

struct FollowGoalWidgetView: View {
    @Environment(\.widgetFamily) private var family: WidgetFamily
    var entry: FollowGoalWidget.Provider.Entry
    
    var maxGauge: Double {
        return entry.followers >= entry.configuration.goal ? Double(entry.followers) : Double(entry.configuration.goal)
    }
    
    var body: some View {
        if let account = entry.configuration.account {
            ZStack {
                if family == WidgetFamily.systemMedium {
                    medium
                } else if family == WidgetFamily.accessoryRectangular {
                    rectangular
                } else if family == WidgetFamily.accessoryCircular {
                    circular
                } else {
                    Text(String("Unsupported WidgetFamily"))
                        .font(.caption)
                }
            }
            .modelContainer(for: [LoggedAccount.self])
        } else {
            Text("widget.select-account")
                .font(.caption)
        }
    }
    
    var medium: some View {
        VStack(alignment: .center) {
            HStack(alignment: .center, spacing: 7.5) {
                Image(uiImage: entry.pfp)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.white)
                    .clipShape(Circle())
                
                Text("@\(entry.configuration.account!.username)")
                    .redacted(reason: .privacy)
                    .font(.caption.bold())
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 7.5)

            
            HStack(alignment: .center, spacing: 7.5) {
                Text(entry.followers, format: .number.notation(.compactName))
                    .font(.title.monospacedDigit().bold())
                    .contentTransition(.numericText())
                Text("widget.followers")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                
                Spacer()
            }
            .padding(.horizontal, 7.5)
            
            Gauge(value: Double(entry.followers), in: 0...maxGauge) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            } minimumValueLabel: {
                Text(0, format: .number.notation(.compactName))
            } maximumValueLabel: {
                Text(entry.configuration.goal, format: .number.notation(.compactName))
            }
            .gaugeStyle(.linearCapacity)
            .tint(Double(entry.followers) >= maxGauge ? Color.green : Color.blue)
            .labelsHidden()
        }
    }
    
    var rectangular: some View {
        Gauge(value: Double(entry.followers), in: 0...maxGauge) {
            Text("@\(entry.configuration.account!.username)")
                .multilineTextAlignment(.leading)
                .font(.caption)
                .opacity(0.7)
        } currentValueLabel: {
            HStack {
                Text(entry.followers, format: .number.notation(.compactName))
                    .font(.caption.monospacedDigit().bold())
                    .contentTransition(.numericText())
                Text("widget.followers")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
        } minimumValueLabel: {
            Text(0, format: .number.notation(.compactName))
        } maximumValueLabel: {
            Text(entry.configuration.goal, format: .number.notation(.compactName))
        }
        .gaugeStyle(.accessoryLinearCapacity)
    }
    
    var circular: some View {
        Gauge(value: Double(entry.followers), in: 0...maxGauge) {
            EmptyView()
        } currentValueLabel: {
            Text(entry.followers, format: .number.notation(.compactName))
                .multilineTextAlignment(.center)
        } minimumValueLabel: {
            EmptyView()
        } maximumValueLabel: {
            EmptyView()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(Double(entry.followers) >= maxGauge ? Color.green : Color.blue)
    }
}

struct FollowGoalWidget: Widget {
    let kind: String = "FollowGoalWidget"
    let modelContainer: ModelContainer
    
    init() {
        guard let modelContainer: ModelContainer = try? .init(for: LoggedAccount.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) else { fatalError("Couldn't get LoggedAccounts") }
        self.modelContainer = modelContainer
    }
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: AccountGoalAppIntent.self, provider: Provider()) { entry in
            FollowGoalWidgetView(entry: entry)
                .containerBackground(Color("WidgetBackground"), for: .widget)
        }
        .configurationDisplayName("widget.follow-goal")
        .description("widget.follow-goal.description")
        .supportedFamilies([.systemMedium, .accessoryRectangular, .accessoryCircular])
    }
    
    struct Provider: AppIntentTimelineProvider {
        func placeholder(in context: Context) -> SimpleEntry {
            let placeholder: UIImage = UIImage(systemName: "person.crop.circle") ?? UIImage()
            placeholder.withTintColor(UIColor.label)
            return SimpleEntry(date: Date(), pfp: placeholder, followers: 38, configuration: AccountGoalAppIntent())
        }
        
        func snapshot(for configuration: AccountGoalAppIntent, in context: Context) async -> SimpleEntry {
            let data = await getData(configuration: configuration)
            return SimpleEntry(date: Date(), pfp: data.0, followers: data.1, configuration: configuration)
        }
        
        func timeline(for configuration: AccountGoalAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
            var entries: [SimpleEntry] = []
            
            let data = await getData(configuration: configuration)
            
            // Generate a timeline consisting of two entries an hour apart, starting from the current date.
            let currentDate = Date()
            for hourOffset in 0 ..< 2 {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                let entry = SimpleEntry(date: entryDate, pfp: data.0, followers: data.1, configuration: configuration)
                entries.append(entry)
            }
            
            return Timeline(entries: entries, policy: .atEnd)
        }
        
        private func getData(configuration: AccountGoalAppIntent) async -> (UIImage, Int) {
            var pfp: UIImage = UIImage(systemName: "person.crop.circle") ?? UIImage()
            pfp.withTintColor(UIColor.label)
            if let account = configuration.account {
                do {
                    let acc = try await account.client.getString(endpoint: Accounts.verifyCredentials, forceVersion: .v1)
                    
                    if let serialized: [String : Any] = try JSONSerialization.jsonObject(with: acc.data(using: String.Encoding.utf8) ?? Data()) as? [String : Any] {
                        let avatar: String = serialized["avatar"] as! String
                        let task = try await URLSession.shared.data(from: URL(string: avatar)!)
                        pfp = UIImage(data: task.0) ?? UIImage()
                        
                        let followers: Int = serialized["followers_count"] as! Int
                        return (pfp, followers)
                    }
                } catch {
                    print(error)
                }
            }
            return (pfp, 0)
        }
    }
    
    struct SimpleEntry: TimelineEntry {
        let date: Date
        let pfp: UIImage
        let followers: Int
        let configuration: AccountGoalAppIntent
    }
}

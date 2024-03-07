//Made by Lumaa

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let placeholder: UIImage = UIImage(systemName: "person.crop.circle") ?? UIImage()
        placeholder.withTintColor(UIColor.label)
        return SimpleEntry(date: Date(), pfp: placeholder, followers: 38, configuration: AccountAppIntent())
    }

    func snapshot(for configuration: AccountAppIntent, in context: Context) async -> SimpleEntry {
        let data = await getData(configuration: configuration)
        return SimpleEntry(date: Date(), pfp: data.0, followers: data.1, configuration: configuration)
    }
    
    func timeline(for configuration: AccountAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
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
    
    private func getData(configuration: AccountAppIntent) async -> (UIImage, Int) {
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
    let configuration: AccountAppIntent
}

struct FollowCountWidgetView: View {
    @Environment(\.widgetFamily) private var family: WidgetFamily
    var entry: Provider.Entry
    
    var body: some View {
        if let account = entry.configuration.account {
            ZStack {
                if family == WidgetFamily.systemSmall {
                    small
                } else if family == WidgetFamily.systemMedium {
                    medium
                } else if family == WidgetFamily.accessoryRectangular {
                    rectangular
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
    
    var small: some View {
        VStack(alignment: .center) {
            Image(uiImage: entry.pfp)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(Color.white)
                .clipShape(Circle())
            
            Spacer()
            
            Text(entry.followers, format: .number.notation(.compactName))
                .font(.title.monospacedDigit().bold())
                .contentTransition(.numericText())
            Text("widget.followers")
                .font(.caption)
                .foregroundStyle(Color.gray)
            
            Spacer()
            
            Text("@\(entry.configuration.account!.username)")
                .redacted(reason: .privacy)
                .font(.caption.bold())
        }
    }
    
    var medium: some View {
        HStack {
            Spacer()
            
            VStack(alignment: .center, spacing: 10) {
                Image(uiImage: entry.pfp)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(Color.white)
                    .clipShape(Circle())
                
                Text("@\(entry.configuration.account!.username)")
                    .redacted(reason: .privacy)
                    .font(.caption.bold())
            }
            
            Spacer()
            
            VStack {
                Text(entry.followers, format: .number.notation(.compactName))
                    .font(.title.monospacedDigit().bold())
                    .contentTransition(.numericText())
                Text("widget.followers")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
            
            Spacer()
        }
    }
    
    var rectangular: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("@\(entry.configuration.account!.username)")
                    .multilineTextAlignment(.leading)
                    .font(.caption)
                    .opacity(0.7)
                
                Text(entry.followers, format: .number.notation(.compactName))
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 32, weight: .bold).monospacedDigit())
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 7.5)
            
            Spacer()
        }
    }
}

struct FollowCountWidget: Widget {
    let kind: String = "FollowCountWidget"
    let modelContainer: ModelContainer
    
    init() {
        guard let modelContainer: ModelContainer = try? .init(for: LoggedAccount.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) else { fatalError("Couldn't get LoggedAccounts") }
        self.modelContainer = modelContainer
    }

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: AccountAppIntent.self, provider: Provider()) { entry in
            FollowCountWidgetView(entry: entry)
                .containerBackground(Color("WidgetBackground"), for: .widget)
        }
        .configurationDisplayName("widget.follow-count")
        .description("widget.follow-count.description")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

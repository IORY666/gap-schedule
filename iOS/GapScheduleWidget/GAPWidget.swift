import WidgetKit
import SwiftUI

struct WEntry: TimelineEntry {
    let date: Date
    let emoji: String
    let name: String
}

struct WProvider: TimelineProvider {
    func placeholder(in context: Context) -> WEntry {
        WEntry(date: Date(), emoji: "🔥", name: "GAP")
    }
    func getSnapshot(in context: Context, completion: @escaping (WEntry) -> Void) {
        completion(WEntry(date: Date(), emoji: "🔥", name: "GAP 训练日"))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WEntry>) -> Void) {
        let now = Date()
        let dow = Calendar.current.component(.weekday, from: now)
        let isRest = dow == 7
        let tasks = ["🏃有氧","📖面试","💪力量","📤投简历","😴睡觉"]
        let hour = Calendar.current.component(.hour, from: now)
        let name = isRest ? "🌴 休息日" : (hour < 12 ? tasks[min(hour-6,4)] : tasks.last!)
        let entry = WEntry(date: now, emoji: isRest ? "🌴" : "🔥", name: name)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct WView: View {
    let entry: WEntry
    var body: some View {
        VStack(spacing: 4) {
            Text(entry.emoji).font(.largeTitle)
            Text(entry.name).font(.caption).fontWeight(.medium).lineLimit(2)
            Text("GAP").font(.caption2).foregroundColor(.orange)
        }.padding(10).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@main
struct GAPWidget: Widget {
    let kind = "GAPWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WProvider()) { WView(entry: $0) }
            .configurationDisplayName("GAP")
            .description("今日任务提醒")
            .supportedFamilies([.systemSmall])
    }
}

import WidgetKit
import SwiftUI

// MARK: - 数据模型（Widget 内嵌，不依赖 App）

struct WidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let isRest: Bool
    let currentTask: WidgetTask?
}

struct WidgetTask: Identifiable {
    let id: Int; let emoji: String; let time: String; let name: String
}

// 默认14个任务
private let allWidgetTasks: [WidgetTask] = [
    WidgetTask(id: 0,  emoji: "🏃", time: "07:00", name: "空腹有氧"),
    WidgetTask(id: 1,  emoji: "🧹", time: "07:45", name: "洗漱整理"),
    WidgetTask(id: 2,  emoji: "🛒", time: "08:00", name: "买菜"),
    WidgetTask(id: 3,  emoji: "☕", time: "08:30", name: "早餐"),
    WidgetTask(id: 4,  emoji: "📖", time: "09:00", name: "背面试题·上午"),
    WidgetTask(id: 5,  emoji: "🍳", time: "11:30", name: "做午饭"),
    WidgetTask(id: 6,  emoji: "🍽", time: "12:30", name: "午餐+午休"),
    WidgetTask(id: 7,  emoji: "📖", time: "14:00", name: "背面试题·下午"),
    WidgetTask(id: 8,  emoji: "📤", time: "16:00", name: "投简历"),
    WidgetTask(id: 9,  emoji: "🍳", time: "17:00", name: "做晚饭"),
    WidgetTask(id: 10, emoji: "🍽", time: "18:00", name: "晚餐+休息"),
    WidgetTask(id: 11, emoji: "💪", time: "19:00", name: "力量+有氧"),
    WidgetTask(id: 12, emoji: "🛀", time: "20:20", name: "洗漱放松"),
    WidgetTask(id: 13, emoji: "😴", time: "22:30", name: "睡觉"),
]

// MARK: - Provider

struct GAPProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), tasks: allWidgetTasks, isRest: false,
                    currentTask: allWidgetTasks[4])
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> WidgetEntry {
        let now = Date()
        let dow = Calendar.current.component(.weekday, from: now) // 1=Sun, 7=Sat
        let isRest = dow == 7
        let nowMin = Calendar.current.component(.hour, from: now) * 60
                   + Calendar.current.component(.minute, from: now)

        let current = allWidgetTasks.first { t in
            let parts = t.time.split(separator: ":")
            let h = Int(parts[0]) ?? 0
            let m = Int(parts[1]) ?? 0
            let start = h * 60 + m
            return nowMin >= start && nowMin < start + 60
        }

        return WidgetEntry(date: now, tasks: allWidgetTasks, isRest: isRest,
                           currentTask: current)
    }
}

// MARK: - 小尺寸 Widget

struct GAPSmallView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(spacing: 4) {
            Text("GAP").font(.caption).fontWeight(.bold).foregroundColor(.orange)
            if entry.isRest {
                Text("🌴").font(.largeTitle)
                Text("休息日").font(.caption2).foregroundColor(.secondary)
            } else if let task = entry.currentTask {
                Text(task.emoji).font(.largeTitle)
                Text(task.name).font(.caption2).fontWeight(.medium).lineLimit(1)
                Text(task.time).font(.system(size: 10, design: .monospaced)).foregroundColor(.orange)
            } else {
                Text("🔥").font(.largeTitle)
                Text("训练日").font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - 中尺寸 Widget

struct GAPMediumView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("GAP").font(.caption).fontWeight(.bold).foregroundColor(.orange)
                Spacer()
                Text(entry.isRest ? "🌴 休息" : "🔥 训练").font(.caption2).foregroundColor(.secondary)
            }.padding(.horizontal, 12).padding(.top, 8)

            if entry.isRest {
                Spacer()
                Text("🌴 好好休息").font(.title2).foregroundColor(.secondary)
                Spacer()
            } else {
                // 显示前5个未到时间的任务
                let upcoming = entry.tasks.filter { t in
                    let parts = t.time.split(separator: ":")
                    let h = Int(parts[0]) ?? 0; let m = Int(parts[1]) ?? 0
                    let nowMin = Calendar.current.component(.hour, from: Date()) * 60
                               + Calendar.current.component(.minute, from: Date())
                    return (h * 60 + m) >= nowMin
                }.prefix(5)

                VStack(spacing: 2) {
                    ForEach(Array(upcoming)) { task in
                        let isCurrent = task.id == entry.currentTask?.id
                        HStack(spacing: 6) {
                            Text(task.emoji).font(.system(size: 14))
                            Text(task.name).font(.system(size: 11)).lineLimit(1)
                                .foregroundColor(isCurrent ? .primary : .secondary)
                                .fontWeight(isCurrent ? .bold : .regular)
                            Spacer()
                            Text(task.time).font(.system(size: 9, design: .monospaced))
                                .foregroundColor(isCurrent ? .orange : .secondary)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 3)
                        .background(isCurrent ? Color.orange.opacity(0.08) : Color.clear)
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Widget 主体

struct GAPWidget: Widget {
    let kind = "GAPWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GAPProvider()) { entry in
            GAPWidgetView(entry: entry)
        }
        .configurationDisplayName("GAP 任务")
        .description("查看今日任务和当前待办")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct GAPWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: WidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            GAPSmallView(entry: entry)
        default:
            GAPMediumView(entry: entry)
        }
    }
}

import SwiftUI

struct TaskEditorView: View {
    @EnvironmentObject var store: TaskStore
    @Environment(\.dismiss) private var dismiss
    @State private var items: [EditableItem] = []

    var body: some View {
        NavigationView {
            List {
                ForEach(0..<items.count, id: \.self) { i in
                    VStack(spacing: 4) {
                        HStack {
                            TextField("E", text: Binding(get: { items[i].emoji }, set: { items[i].emoji = $0 }))
                                .font(.title2).frame(width: 36)
                            TextField("时间", text: Binding(get: { items[i].time }, set: { items[i].time = $0 }))
                                .font(.caption).foregroundColor(.orange).frame(width: 105)
                            TextField("名称", text: Binding(get: { items[i].name }, set: { items[i].name = $0 }))
                                .font(.body)
                        }
                        TextField("详情", text: Binding(get: { items[i].detail }, set: { items[i].detail = $0 }))
                            .font(.caption2).foregroundColor(.secondary)
                    }.padding(.vertical, 4)
                }
                .onDelete { off in if items.count > 1 { items.remove(atOffsets: off) } }
                .onMove { from, to in items.move(fromOffsets: from, toOffset: to) }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { items.append(EditableItem.new(id: items.count)) }) { Image(systemName: "plus") }
                        Button("保存") {
                            store.save(items.map { $0.toTask() })
                            NotificationManager.shared.refreshAll()
                            dismiss()
                        }.fontWeight(.bold)
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("恢复默认") { store.reset(); items = store.tasks.map(EditableItem.init); NotificationManager.shared.refreshAll() }.font(.caption)
                }
            }
        }
        .onAppear { items = store.tasks.map(EditableItem.init) }
    }
}

struct EditableItem {
    var emoji: String; var time: String; var name: String; var detail: String; var id: Int
    init(from t: TaskItem) { emoji = t.emoji; time = t.timeRange; name = t.name; detail = t.detail; id = t.id }
    static func new(id: Int) -> EditableItem { EditableItem(emoji: "📌", time: "12:00-13:00", name: "新任务", detail: "点击编辑", id: id) }
    func toTask() -> TaskItem { TaskItem(id: id, emoji: emoji, timeRange: time, name: name, detail: detail) }
}

import SwiftUI

struct TaskEditorView: View {
    @EnvironmentObject var store: TaskStore
    @Environment(\.dismiss) private var dismiss
    @State private var editable: [EditableTask]

    init() { _editable = State(initialValue: []) }

    var body: some View {
        NavigationView {
            List {
                ForEach(0..<editable.count, id: \.self) { i in
                    VStack(spacing: 6) {
                        HStack {
                            TextField("Emoji", text: Binding(get: { editable[i].emoji }, set: { editable[i].emoji = $0 }))
                                .font(.title2).frame(width: 40)
                            TextField("时间", text: Binding(get: { editable[i].time }, set: { editable[i].time = $0 }))
                                .font(.caption).foregroundColor(.orange).frame(width: 105)
                            TextField("名称", text: Binding(get: { editable[i].name }, set: { editable[i].name = $0 }))
                                .font(.body)
                        }
                        TextField("详情", text: Binding(get: { editable[i].detail }, set: { editable[i].detail = $0 }))
                            .font(.caption2).foregroundColor(.secondary)
                    }.padding(.vertical, 4)
                }
                .onDelete { off in if editable.count > 1 { editable.remove(atOffsets: off) } }
                .onMove { from, to in editable.move(fromOffsets: from, toOffset: to) }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { editable.append(EditableTask.new(id: store.tasks.count)) }) {
                            Image(systemName: "plus")
                        }
                        Button("保存") {
                            store.save(editable.map { $0.toItem() })
                            NotificationManager.shared.refreshAll()
                            dismiss()
                        }.fontWeight(.bold)
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("恢复默认") {
                        store.resetToDefault()
                        editable = store.tasks.map(EditableTask.init)
                        NotificationManager.shared.refreshAll()
                    }.font(.caption)
                }
            }
        }
        .onAppear { editable = store.tasks.map(EditableTask.init) }
    }
}

struct EditableTask {
    var emoji: String; var time: String; var name: String; var detail: String; var id: Int

    init(from t: TaskItem) {
        emoji = t.emoji; time = t.timeRange; name = t.name; detail = t.detail; id = t.id
    }
    static func new(id: Int) -> EditableTask {
        EditableTask(emoji: "📌", time: "12:00-13:00", name: "新任务", detail: "点击编辑", id: id)
    }
    func toItem() -> TaskItem {
        TaskItem(id: id, emoji: emoji, timeRange: time, name: name, detail: detail)
    }
}

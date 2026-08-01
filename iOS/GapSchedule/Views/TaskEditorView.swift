import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editable: [EditableTask]

    init() { _editable = State(initialValue: TaskStore.shared.load().map(EditableTask.init)) }

    var body: some View {
        NavigationView {
            List {
                ForEach(0..<editable.count, id: \.self) { i in
                    VStack(spacing: 5) {
                        HStack {
                            TextField("Emoji", text: Binding(
                                get: { editable[i].emoji },
                                set: { editable[i].emoji = $0 }
                            )).font(.system(size: 22)).frame(width: 36)
                            TextField("HH:MM-HH:MM", text: Binding(
                                get: { editable[i].time },
                                set: { editable[i].time = $0 }
                            )).font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color(hex: "f0a040")).frame(width: 105)
                            TextField("任务名", text: Binding(
                                get: { editable[i].name },
                                set: { editable[i].name = $0 }
                            )).font(.system(size: 13)).foregroundColor(.white)
                        }
                        TextField("详情", text: Binding(
                            get: { editable[i].detail },
                            set: { editable[i].detail = $0 }
                        )).font(.system(size: 11)).foregroundColor(Color.white.opacity(0.4))
                    }.padding(.vertical, 4)
                }
                .onDelete { off in
                    if editable.count > 1 { editable.remove(atOffsets: off) }
                }
                .onMove { from, to in editable.move(fromOffsets: from, toOffset: to) }
            }
            .listStyle(.plain)
            .background(Color(hex: "1a1b1e"))
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { editable.append(EditableTask.new()) }) {
                            Image(systemName: "plus")
                        }
                        Button("保存") {
                            TaskStore.shared.save(editable.map { $0.toItem() })
                            dismiss()
                        }.fontWeight(.bold)
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button("恢复默认") {
                            TaskStore.shared.reset()
                            editable = TaskStore.shared.load().map(EditableTask.init)
                        }.font(.system(size: 11)).foregroundColor(Color.white.opacity(0.4))
                        Spacer()
                        Text("长按拖拽排序").font(.system(size: 10)).foregroundColor(Color.white.opacity(0.25))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 可编辑模型

struct EditableTask {
    var emoji: String
    var time: String
    var name: String
    var detail: String

    init(emoji: String, time: String, name: String, detail: String) {
        self.emoji = emoji; self.time = time; self.name = name; self.detail = detail
    }
    init(from t: TaskItem) {
        emoji = t.emoji; time = t.timeRange; name = t.name; detail = t.detail
    }
    static func new() -> EditableTask {
        EditableTask(emoji: "📌", time: "12:00-13:00", name: "新任务", detail: "点击编辑")
    }
    func toItem() -> TaskItem {
        TaskItem(id: TaskStore.shared.nextId, emoji: emoji, timeRange: time, name: name, detail: detail)
    }
}

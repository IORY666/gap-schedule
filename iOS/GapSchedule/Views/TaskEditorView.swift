import SwiftUI

/// 任务编辑器：添加/删除/排序/保存
struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tasks: [EditableTask]

    init() {
        _tasks = State(initialValue: TaskStore.shared.load().map { EditableTask(from: $0) })
    }

    var body: some View {
        NavigationView {
            List {
                ForEach($tasks) { $task in
                    VStack(spacing: 6) {
                        HStack {
                            TextField("Emoji", text: $task.emoji)
                                .font(.system(size: 22))
                                .frame(width: 36)
                            TextField("HH:MM-HH:MM", text: $task.time)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(hex: "f0a040"))
                                .frame(width: 100)
                            TextField("任务名", text: $task.name)
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                        }
                        TextField("详情", text: $task.detail)
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { idx in
                    if tasks.count > 1 { tasks.remove(atOffsets: idx) }
                }
                .onMove { from, to in tasks.move(fromOffsets: from, toOffset: to) }
            }
            .listStyle(.plain)
            .background(Color(hex: "1a1b1e"))
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { tasks.append(EditableTask.new()) }) {
                            Image(systemName: "plus")
                        }
                        Button("保存") {
                            TaskStore.shared.save(tasks.map { $0.toTaskItem() })
                            dismiss()
                        }
                        .fontWeight(.bold)
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button("恢复默认") {
                            TaskStore.shared.reset()
                            tasks = TaskStore.shared.load().map { EditableTask(from: $0) }
                        }
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.4))
                        Spacer()
                        Text("长按拖拽排序 · 左滑删除")
                            .font(.system(size: 10))
                            .foregroundColor(Color.white.opacity(0.25))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 可编辑任务模型

struct EditableTask: Identifiable {
    var id = UUID()
    var emoji: String
    var time: String
    var name: String
    var detail: String

    init(from item: TaskItem) {
        self.emoji = item.emoji
        self.time = item.timeRange
        self.name = item.name
        self.detail = item.detail
    }

    static func new() -> EditableTask {
        EditableTask(emoji: "📌", time: "12:00-13:00", name: "新任务", detail: "点击编辑")
    }

    func toTaskItem() -> TaskItem {
        let nextId = TaskStore.shared.nextId
        return TaskItem(id: nextId, emoji: emoji, timeRange: time, name: name, detail: detail)
    }
}

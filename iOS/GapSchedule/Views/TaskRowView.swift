import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let isCurrent: Bool
    @EnvironmentObject var manager: ScheduleManager

    private var isDone: Bool { manager.dayProgress.checked.contains(task.id) }

    var body: some View {
        HStack(spacing: 10) {
            // 当前任务金色左边条
            if isCurrent {
                Rectangle()
                    .fill(Color(hex: "f0a040"))
                    .frame(width: 3)
                    .cornerRadius(2)
            }

            // Emoji
            Text(task.emoji)
                .font(.system(size: 20))
                .frame(width: 28)

            // 文字区
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(task.timeRange)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "f0a040"))

                    if !isDone && !manager.isRestDay {
                        Text("🔔")
                            .font(.system(size: 9))
                    }
                }

                Text(isDone ? "✓ \(task.name)" : task.name)
                    .font(.system(size: 13))
                    .foregroundColor(isDone ? Color.white.opacity(0.4) : .white)
                    .strikethrough(isDone)

                Text(task.detail)
                    .font(.system(size: 10))
                    .foregroundColor(Color.white.opacity(0.4))
            }

            Spacer()

            // 勾选按钮
            Button(action: { manager.toggle(task.id) }) {
                Image(systemName: isDone ? "circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isDone ? Color(hex: "57d97c") : Color.white.opacity(0.25))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isCurrent ? Color.white.opacity(0.08) : Color.clear)
        .cornerRadius(8)
    }
}

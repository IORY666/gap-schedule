import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: TaskStore
    @EnvironmentObject var settings: AppSettings
    @StateObject private var manager = ScheduleManager.shared
    @State private var selectedDate = Date()
    @State private var showReminder: (TaskItem, Bool)? = nil
    @State private var currentMinute = 0
    @State private var showEditor = false

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 日期 + 标签卡片
                    dateCard
                    // 日历卡片
                    calendarCard
                    // 任务卡片
                    tasksCard
                }
                .padding(12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("GAP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showEditor = true }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showEditor) { TaskEditorView() }
            .onReceive(timer) { _ in checkAlerts() }

            // 弹窗
            if let (task, isOnTime) = showReminder {
                Color.black.opacity(0.5).ignoresSafeArea()
                ReminderPopupView(task: task, isOnTime: isOnTime,
                                  onDismiss: { showReminder = nil })
                    .environmentObject(manager)
                    .padding(24)
            }
        }
    }

    // MARK: - 日期卡片
    private var dateCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                let dow = Calendar.current.component(.weekday, from: Date()) - 1
                Text(weekdays[dow]).font(.headline).foregroundColor(.orange)
                Text("\(Calendar.current.component(.month, from: Date()))月\(Calendar.current.component(.day, from: Date()))日")
                    .font(.largeTitle).fontWeight(.bold)
            }
            Spacer()
            Text(manager.resting ? "🌴 休息日" : "🔥 训练日")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(manager.resting ? .green : .white)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(manager.resting ? Color.green.opacity(0.15) : Color.orange, in: Capsule())
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    // MARK: - 日历卡片
    private var calendarCard: some View {
        CalendarGridView(selectedDate: $selectedDate)
            .padding(8)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    // MARK: - 任务卡片
    private var tasksCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(store.tasks.enumerated()), id: \.element.id) { idx, task in
                let isCur = task.id == manager.currentTaskId
                taskRow(task, isCurrent: isCur)
                if idx < store.tasks.count - 1 {
                    Divider().padding(.leading, 48)
                }
            }

            Divider().padding(.top, 8)
            // 进度条
            HStack {
                Text("已完成 \(manager.dayProgress.checked.count)/\(store.tasks.count)")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
                ProgressView(value: Double(manager.dayProgress.checked.count),
                             total: Double(max(1, store.tasks.count)))
                    .tint(.orange).frame(width: 100)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    // MARK: - 单行任务
    private func taskRow(_ task: TaskItem, isCurrent: Bool) -> some View {
        HStack(spacing: 10) {
            Text(task.emoji).font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(task.timeRange)
                        .font(.caption2).fontWeight(.medium).foregroundColor(.orange)
                    if !manager.dayProgress.checked.contains(task.id) && !manager.resting {
                        Text("🔔").font(.system(size: 9))
                    }
                }
                Text(task.name)
                    .font(.subheadline)
                    .foregroundColor(manager.dayProgress.checked.contains(task.id) ? .secondary : .primary)
                Text(task.detail).font(.caption2).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            Button(action: { manager.toggle(task.id) }) {
                Image(systemName: manager.dayProgress.checked.contains(task.id)
                      ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(manager.dayProgress.checked.contains(task.id) ? .green : .quaternaryLabel)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(isCurrent ? Color.orange.opacity(0.08) : Color.clear)
    }

    // MARK: -
    private func checkAlerts() {
        let now = Calendar.current.component(.hour, from: Date()) * 60
                 + Calendar.current.component(.minute, from: Date())
        guard now != currentMinute else { return }
        currentMinute = now
        if settings.reminderEnabled, let first = manager.tasksNeedingAlert(nowMin: now).first {
            showReminder = first
        }
    }
}

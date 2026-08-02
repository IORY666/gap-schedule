import SwiftUI

struct ContentView: View {
    @StateObject private var store = TaskStore.shared
    @StateObject private var manager = ScheduleManager.shared
    @StateObject private var settings = AppSettings.shared
    @State private var selectedDate = Date()
    @State private var showReminder: (TaskItem, Bool)? = nil
    @State private var currentMinute = 0
    @State private var showEditor = false
    @State private var showDashboard = false
    @State private var showSettings = false

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 顶栏 — 原生风格
                HStack {
                    Text("GAP").font(.title2).fontWeight(.bold)
                    Spacer()
                    Button(action: { showSettings = true }) { Image(systemName: "gearshape").font(.title3) }
                    Button(action: { showDashboard = true }) { Image(systemName: "chart.bar").font(.title3) }
                    Button(action: { showEditor = true }) { Image(systemName: "pencil").font(.title3) }
                }
                .padding(.horizontal).padding(.vertical, 10)

                Divider()

                // 日期 + 标签
                HStack {
                    let dow = Calendar.current.component(.weekday, from: Date()) - 1
                    Text("\(Calendar.current.component(.month, from: Date()))月\(Calendar.current.component(.day, from: Date()))日 \(weekdays[dow])")
                        .font(.title3).fontWeight(.semibold)
                    Spacer()
                    badge
                }.padding(.horizontal).padding(.vertical, 6)

                Divider()

                // 日历
                CalendarGridView(selectedDate: $selectedDate)
                    .padding(.horizontal).padding(.vertical, 4)
                Divider()

                // 任务列表（仅此区域滚动）
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.tasks) { task in
                            let isCur = task.id == manager.currentTaskId
                            TaskRowView(task: task, isCurrent: isCur)
                                .environmentObject(manager)
                            Divider().padding(.leading, 46)
                        }
                    }.padding(.vertical, 4)
                }

                Divider()
                // 底部进度（固定）
                HStack {
                    Text("进度 \(manager.dayProgress.checked.count)/\(store.tasks.count)")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    ProgressView(value: Double(manager.dayProgress.checked.count), total: Double(max(1, store.tasks.count)))
                        .tint(.orange).frame(width: 120)
                }.padding(.horizontal).padding(.vertical, 8)
            }
            .background(Color(.systemBackground))

            // 弹窗
            if let (task, isOnTime) = showReminder {
                Color.black.opacity(0.5).ignoresSafeArea()
                ReminderPopupView(task: task, isOnTime: isOnTime,
                                  onDismiss: { showReminder = nil })
                    .environmentObject(manager)
                    .frame(maxWidth: 340)
            }
        }
        .sheet(isPresented: $showEditor) { TaskEditorView().environmentObject(store) }
        .sheet(isPresented: $showDashboard) { DashboardView() }
        .sheet(isPresented: $showSettings) { SettingsView().environmentObject(settings) }
        .onReceive(timer) { _ in checkAlerts() }
        .onAppear {
            NotificationManager.shared.requestAuth()
            NotificationManager.shared.registerCategories()
            NotificationManager.shared.scheduleAllIfNeeded()
            checkAlerts()
        }
    }

    private var badge: some View {
        Text(manager.isRestDay ? "🌴 休息" : "🔥 训练")
            .font(.caption).fontWeight(.bold).foregroundColor(.white)
            .padding(.horizontal, 10).padding(.vertical, 3)
            .background(manager.isRestDay ? Color.green : Color.orange, in: Capsule())
    }

    private func checkAlerts() {
        let now = Calendar.current.component(.hour, from: Date()) * 60
                 + Calendar.current.component(.minute, from: Date())
        guard now != currentMinute else { return }
        currentMinute = now
        if let first = manager.tasksNeedingAlert(nowMin: now).first {
            showReminder = first
        }
    }
}

import SwiftUI

struct ContentView: View {
    @StateObject private var manager = ScheduleManager.shared
    @State private var selectedDate = Date()
    @State private var showReminder: (TaskItem, Bool)? = nil
    @State private var currentMinute = 0
    @State private var showEditor = false
    @State private var showDashboard = false
    @State private var tasks: [TaskItem] = TaskStore.shared.load()

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 主界面
            VStack(spacing: 0) {
                headerView
                Divider().background(Color.white.opacity(0.1))
                dateBadgeView.padding(.horizontal, 16)
                Divider().background(Color.white.opacity(0.1))
                CalendarGridView(selectedDate: $selectedDate)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                Divider().background(Color.white.opacity(0.1))

                ScrollView {
                    taskListView.padding(.horizontal, 16).padding(.vertical, 8)
                }.frame(maxHeight: .infinity)

                Divider().background(Color.white.opacity(0.1))
                progressView.padding(.horizontal, 16).padding(.vertical, 10)
            }
            .background(Color(hex: "1a1b1e").ignoresSafeArea())

            // 弹窗
            if let (task, isOnTime) = showReminder {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                ReminderPopupView(task: task, isOnTime: isOnTime,
                                  onDismiss: { showReminder = nil })
                    .environmentObject(manager)
                    .frame(maxWidth: 320)
            }
        }
        .onReceive(timer) { _ in
            checkAlerts()
        }
        .sheet(isPresented: $showEditor) { TaskEditorView() }
        .sheet(isPresented: $showDashboard) { DashboardView() }
        .onReceive(NotificationCenter.default.publisher(for: .tasksDidChange)) { n in
            if let t = n.object as? [TaskItem] { tasks = t; manager.refresh() }
        }
        .onAppear {
            tasks = TaskStore.shared.load()
            NotificationManager.shared.requestAuth()
            NotificationManager.shared.registerCategories()
            NotificationManager.shared.scheduleAllIfNeeded()
            checkAlerts()
        }
    }

    // MARK: - 子视图

    private var headerView: some View {
        HStack {
            Text("🔥 Gap 任务日历")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button(action: { showDashboard = true }) { Text("📊").font(.system(size: 16)) }
            Button(action: { showEditor = true }) { Text("📝").font(.system(size: 16)) }
            Text(Date(), style: .time)
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var dateBadgeView: some View {
        HStack {
            let dow = Calendar.current.component(.weekday, from: Date()) - 1
            Text("\(Calendar.current.component(.month, from: Date()))月\(Calendar.current.component(.day, from: Date()))日 \(weekdays[dow])")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            if manager.isRestDay {
                Text("🌴 休息日")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(hex: "57d97c"))
                    .cornerRadius(12)
            } else {
                Text("🔥 训练日")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(hex: "f0a040"))
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 8)
    }

    private var taskListView: some View {
        VStack(spacing: 4) {
            ForEach(tasks) { task in
                let isCur = task.id == manager.currentTaskId
                TaskRowView(task: task, isCurrent: isCur)
                    .environmentObject(manager)
            }
        }
    }

    private var progressView: some View {
        HStack {
            Text("今日进度 \(manager.dayProgress.checked.count)/\(tasks.count)")
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.4))
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 5)
                        .cornerRadius(2.5)
                    Rectangle()
                        .fill(Color(hex: "f0a040"))
                        .frame(width: geo.size.width * CGFloat(manager.dayProgress.checked.count) / CGFloat(tasks.count), height: 5)
                        .cornerRadius(2.5)
                        .animation(.easeInOut(duration: 0.3), value: manager.dayProgress.checked.count)
                }
            }
            .frame(width: 120, height: 5)
        }
    }

    // MARK: - 闹钟检测

    private func checkAlerts() {
        let now = Calendar.current.component(.hour, from: Date()) * 60
                 + Calendar.current.component(.minute, from: Date())

        guard now != currentMinute else { return }
        currentMinute = now

        let alerts = manager.tasksNeedingAlert(nowMin: now)
        if let first = alerts.first {
            showReminder = first
        }
    }
}

#Preview {
    ContentView()
}

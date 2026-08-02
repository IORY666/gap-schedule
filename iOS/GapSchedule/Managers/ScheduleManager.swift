import Foundation
import Combine

/// 核心调度管理：勾选、离开、snooze、当前任务检测
final class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()

    @Published var dayProgress = DayProgress()
    @Published var snoozedTasks: [Int: Int] = [:] // [taskId: nextAlertMinute]
    @Published var currentTaskId: Int? = nil
    @Published var isRestDay = false

    private var timer: Timer?
    private let storeKey = "gap_day_progress"

    private init() {
        loadProgress()
        updateCurrentTask()
        startTimer()
    }

    // MARK: - 勾选

    func toggle(_ taskId: Int) {
        if dayProgress.checked.contains(taskId) {
            dayProgress.checked.remove(taskId)
            dayProgress.dismissed.remove(taskId)
            snoozedTasks.removeValue(forKey: taskId)
        } else {
            dayProgress.checked.insert(taskId)
            dayProgress.dismissed.insert(taskId)
            snoozedTasks.removeValue(forKey: taskId)
            // 取消该任务的通知
            NotificationManager.shared.cancelTask(taskId, date: Date())
        }
        saveProgress()
    }

    func dismiss(_ taskId: Int) {
        dayProgress.dismissed.insert(taskId)
        snoozedTasks.removeValue(forKey: taskId)
        saveProgress()
    }

    func snooze(taskId: Int, minutes: Int) {
        let now = Calendar.current.component(.hour, from: Date()) * 60
                + Calendar.current.component(.minute, from: Date())
        snoozedTasks[taskId] = now + minutes
        dayProgress.dismissed.remove(taskId)
        // 安排iOS本地通知snooze
        NotificationManager.shared.snooze(taskId: taskId, minutes: minutes)
    }

    // MARK: - 当前任务

    func refresh() {
        updateCurrentTask()
        NotificationManager.shared.refreshAll()
    }

    func updateCurrentTask() {
        isRestDay = isRestDay()

        if isRestDay {
            currentTaskId = nil
            return
        }

        let now = Calendar.current.component(.hour, from: Date()) * 60
                + Calendar.current.component(.minute, from: Date())

        // 已完成/离开的任务不算当前任务
        let active = TaskStore.shared.tasks.filter { t in
            !dayProgress.checked.contains(t.id) && !dayProgress.dismissed.contains(t.id)
        }

        currentTaskId = active.first(where: { now >= $0.startMinutes && now < $0.endMinutes })?.id
    }

    /// 需要弹snooze弹窗的任务（10分钟前 + snooze到期）
    func tasksNeedingAlert(nowMin: Int) -> [(TaskItem, Bool)] {
        // Bool = isOnTime (到点 vs 预告)
        var result: [(TaskItem, Bool)] = []

        for task in TaskStore.shared.tasks {
            guard !dayProgress.checked.contains(task.id),
                  !dayProgress.dismissed.contains(task.id) else { continue }

            // 到点
            if nowMin == task.startMinutes {
                result.append((task, true))
                continue
            }

            // 错过开始但在时段内
            if task.startMinutes < nowMin && nowMin < task.endMinutes {
                result.append((task, true))
                continue
            }

            // snooze到期
            if let snoozedMin = snoozedTasks[task.id], nowMin >= snoozedMin {
                snoozedTasks.removeValue(forKey: task.id)
                if nowMin >= task.startMinutes {
                    result.append((task, true))
                } else {
                    result.append((task, false))
                }
                continue
            }

            // 10分钟前首次提醒
            if nowMin == task.startMinutes - 10 && snoozedTasks[task.id] == nil {
                result.append((task, false))
            }
        }

        return result
    }

    // MARK: - 定时

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateCurrentTask()
            self?.checkCrossDay()
        }
    }

    private func checkCrossDay() {
        let savedDate = UserDefaults.standard.string(forKey: "gap_last_date") ?? ""
        let today = todayKey()
        if savedDate != today {
            UserDefaults.standard.set(today, forKey: "gap_last_date")
            dayProgress = DayProgress()
            snoozedTasks = [:]
            saveProgress()
            // 跨天刷新通知
            NotificationManager.shared.refreshAll()
        }
    }

    // MARK: - 持久化

    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let dp = try? JSONDecoder().decode(DayProgress.self, from: data) else { return }
        dayProgress = dp
    }

    private func saveProgress() {
        guard let data = try? JSONEncoder().encode(dayProgress) else { return }
        UserDefaults.standard.set(data, forKey: storeKey)
    }
}

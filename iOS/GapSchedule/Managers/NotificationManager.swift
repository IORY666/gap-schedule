import UserNotifications

/// 本地通知管理：安排、snooze、取消（所有操作异步，不阻塞主线程）
final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - 权限

    func requestAuth() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, err in
            print("[Notify] auth: \(granted)" + (err.map { " error: \($0)" } ?? ""))
            if granted {
                // 权限拿到后立刻安排通知
                self.scheduleAllIfNeeded()
            }
        }
    }

    // MARK: - 安排通知（今明两天）

    func scheduleAllIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { [weak self] pending in
            guard let self else { return }
            // 少于30条时才补充
            guard pending.count < 30 else {
                print("[Notify] \(pending.count) pending, skip")
                return
            }
            print("[Notify] Scheduling... (\(pending.count) pending)")

            let today = Calendar.current.startOfDay(for: Date())
            for dayOffset in 0...1 {
                guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                if isSaturday(date) { continue }

                for task in currentTasks {
                    self.schedulePreAlert(for: task, on: date)
                    self.scheduleOnTime(for: task, on: date)
                }
            }
        }
    }

    /// 提前10分钟预告
    private func schedulePreAlert(for task: TaskItem, on date: Date) {
        // 用 Calendar 正确计算（处理跨小时、跨天）
        var taskDate = Calendar.current.date(bySettingHour: task.startHour, minute: task.startMin, second: 0, of: date)!
        taskDate = Calendar.current.date(byAdding: .minute, value: -10, to: taskDate)!

        // 如果已经过了 → 跳过
        if taskDate < Date() { return }

        let dc = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: taskDate)
        let id = "pre_\(dateKey(date))_\(task.id)"

        let content = UNMutableNotificationContent()
        content.title = "⏰ 还有10分钟"
        content.body = "\(task.emoji) \(task.name)"
        content.sound = .default
        content.categoryIdentifier = "SNOOZE_CATEGORY"
        content.userInfo = ["taskId": task.id, "type": "pre"]

        add(UNNotificationRequest(identifier: id, content: content,
                                   trigger: UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)))
    }

    /// 到点提醒
    private func scheduleOnTime(for task: TaskItem, on date: Date) {
        var taskDate = Calendar.current.date(bySettingHour: task.startHour, minute: task.startMin, second: 0, of: date)!
        if taskDate < Date() { return }

        let dc = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: taskDate)
        let id = "now_\(dateKey(date))_\(task.id)"

        let content = UNMutableNotificationContent()
        content.title = "🔔 时间到！"
        content.body = "\(task.emoji) \(task.name)"
        content.sound = .default
        content.userInfo = ["taskId": task.id, "type": "now"]

        add(UNNotificationRequest(identifier: id, content: content,
                                   trigger: UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)))
    }

    // MARK: - Snooze

    func snooze(taskId: Int, minutes: Int) {
        guard let task = currentTasks.first(where: { $0.id == taskId }) else { return }

        let id = "snooze_\(taskId)_\(Int(Date().timeIntervalSince1970))"
        let content = UNMutableNotificationContent()
        content.title = "⏰ 推迟提醒"
        content.body = "\(task.emoji) \(task.name)（\(minutes)分钟后）"
        content.sound = .default
        content.categoryIdentifier = "SNOOZE_CATEGORY"
        content.userInfo = ["taskId": task.id, "type": "snooze"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(minutes * 60), repeats: false)
        add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func cancelTask(_ taskId: Int, date: Date) {
        let dk = dateKey(date)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "pre_\(dk)_\(taskId)", "now_\(dk)_\(taskId)"
        ])
    }

    func refreshAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // 等删除完成后再安排
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.scheduleAllIfNeeded()
        }
    }

    // MARK: - 辅助

    private func add(_ request: UNNotificationRequest) {
        UNUserNotificationCenter.current().add(request) { err in
            if let e = err { print("[Notify] add failed: \(e.localizedDescription)") }
        }
    }

    private func dateKey(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-M-d"; return f.string(from: date)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let taskId = userInfo["taskId"] as? Int ?? -1

        switch response.actionIdentifier {
        case "SNOOZE_5":
            snooze(taskId: taskId, minutes: 5)
            ScheduleManager.shared.snooze(taskId: taskId, minutes: 5)
        case "SNOOZE_1":
            snooze(taskId: taskId, minutes: 1)
            ScheduleManager.shared.snooze(taskId: taskId, minutes: 1)
        case "DISMISS":
            ScheduleManager.shared.dismiss(taskId)
        default:
            break
        }
        completionHandler()
    }
}

// MARK: - 通知类别注册

extension NotificationManager {
    func registerCategories() {
        let snooze5 = UNNotificationAction(identifier: "SNOOZE_5", title: "5分钟后", options: [])
        let snooze1 = UNNotificationAction(identifier: "SNOOZE_1", title: "1分钟后", options: [])
        let dismiss_ = UNNotificationAction(identifier: "DISMISS", title: "离开", options: .destructive)

        let cat = UNNotificationCategory(
            identifier: "SNOOZE_CATEGORY",
            actions: [snooze5, snooze1, dismiss_],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        UNUserNotificationCenter.current().setNotificationCategories([cat])
        print("[Notify] Categories registered")
    }
}

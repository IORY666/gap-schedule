import UserNotifications
import UIKit

/// 管理所有本地通知：安排、snooze、取消
final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - 权限

    func requestAuth() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, err in
            if let e = err { print("[Notify] auth error: \(e)") }
            print("[Notify] auth granted: \(granted)")
        }
    }

    // MARK: - 安排通知

    /// 安排今明两天的所有任务通知（10分钟预告 + 到点）
    func scheduleAllIfNeeded() {
        let pending = pendingCount()
        guard pending < 50 else { return } // 已有足够通知

        let today = Calendar.current.startOfDay(for: Date())
        for dayOffset in 0...1 { // 今天 + 明天
            guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            if isSaturday(date) { continue } // 周六休息不通知

            for task in allTasks {
                schedulePreAlert(for: task, on: date)
                scheduleOnTime(for: task, on: date)
            }
        }
    }

    /// 提前10分钟预告通知（支持snooze action）
    private func schedulePreAlert(for task: TaskItem, on date: Date) {
        var dc = DateComponents()
        dc.year  = Calendar.current.component(.year,  from: date)
        dc.month = Calendar.current.component(.month, from: date)
        dc.day   = Calendar.current.component(.day,   from: date)
        dc.hour  = task.startHour
        dc.minute = task.startMin - 10

        // 处理跨小时
        if dc.minute! < 0 {
            dc.minute! += 60
            dc.hour! -= 1
        }
        guard dc.hour! >= 0 else { return }

        let id = "pre_\(dateKey(date))_\(task.id)"
        let content = UNMutableNotificationContent()
        content.title = "⏰ 还有10分钟"
        content.body = "\(task.emoji) \(task.name)"
        content.sound = .default
        content.categoryIdentifier = "SNOOZE_CATEGORY"
        content.userInfo = ["taskId": task.id, "date": dateKey(date), "type": "pre"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    /// 到点通知
    private func scheduleOnTime(for task: TaskItem, on date: Date) {
        var dc = DateComponents()
        dc.year  = Calendar.current.component(.year,  from: date)
        dc.month = Calendar.current.component(.month, from: date)
        dc.day   = Calendar.current.component(.day,   from: date)
        dc.hour  = task.startHour
        dc.minute = task.startMin

        let id = "now_\(dateKey(date))_\(task.id)"
        let content = UNMutableNotificationContent()
        content.title = "🔔 时间到！"
        content.body = "\(task.emoji) \(task.name)"
        content.sound = .default
        content.userInfo = ["taskId": task.id, "date": dateKey(date), "type": "now"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    // MARK: - Snooze

    func snooze(taskId: Int, minutes: Int) {
        guard let task = allTasks.first(where: { $0.id == taskId }) else { return }
        let fireDate = Date().addingTimeInterval(Double(minutes * 60))

        let id = "snooze_\(taskId)_\(Int(fireDate.timeIntervalSince1970))"
        let content = UNMutableNotificationContent()
        content.title = "⏰ Snooze 提醒"
        content.body = "\(task.emoji) \(task.name)（推迟\(minutes)分钟）"
        content.sound = .default
        content.categoryIdentifier = "SNOOZE_CATEGORY"
        content.userInfo = ["taskId": task.id, "date": todayKey(), "type": "snooze"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(minutes * 60), repeats: false)
        add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    /// 取消某个任务当天的所有通知
    func cancelTask(_ taskId: Int, date: Date) {
        let dk = dateKey(date)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "pre_\(dk)_\(taskId)", "now_\(dk)_\(taskId)"
        ])
    }

    /// 刷新所有通知
    func refreshAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        scheduleAllIfNeeded()
    }

    // MARK: - 辅助

    private func add(_ request: UNNotificationRequest) {
        UNUserNotificationCenter.current().add(request) { err in
            if let e = err { print("[Notify] add error: \(e)") }
        }
    }

    private func pendingCount() -> Int {
        var count = 0
        let sem = DispatchSemaphore(value: 0)
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            count = reqs.count
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + 0.5)
        return count
    }

    private func dateKey(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-M-d"; return f.string(from: date)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// 前台显示通知
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    /// 用户点击通知或snooze action
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let taskId = userInfo["taskId"] as? Int ?? -1

        switch response.actionIdentifier {
        case "SNOOZE_5":
            snooze(taskId: taskId, minutes: 5)
        case "SNOOZE_1":
            snooze(taskId: taskId, minutes: 1)
        case "DISMISS":
            // 离开 → App处理
            DispatchQueue.main.async {
                ScheduleManager.shared.dismiss(taskId)
            }
        default:
            break
        }
        completionHandler()
    }
}

// MARK: - 注册通知类别（含snooze actions）

extension NotificationManager {
    func registerCategories() {
        let snooze5 = UNNotificationAction(identifier: "SNOOZE_5", title: "5分钟后", options: [])
        let snooze1 = UNNotificationAction(identifier: "SNOOZE_1", title: "1分钟后", options: [])
        let dismiss_ = UNNotificationAction(identifier: "DISMISS", title: "离开", options: .destructive)

        let category = UNNotificationCategory(
            identifier: "SNOOZE_CATEGORY",
            actions: [snooze5, snooze1, dismiss_],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

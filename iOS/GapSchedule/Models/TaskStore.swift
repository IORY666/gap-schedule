import Foundation

/// 任务持久化管理
final class TaskStore {
    static let shared = TaskStore()
    private let key = "gap_custom_tasks"
    private let nextIdKey = "gap_next_task_id"
    private let defaultCount = 14

    var nextId: Int {
        let id = UserDefaults.standard.integer(forKey: nextIdKey)
        return max(id, defaultCount)
    }

    func load() -> [TaskItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([TaskItem].self, from: data),
              !items.isEmpty
        else { return allTasks } // 返回默认任务
        return items
    }

    func save(_ tasks: [TaskItem]) {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        UserDefaults.standard.set(data, forKey: key)
        // 更新全局可变任务列表
        currentTasks = tasks
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: nextIdKey)
        currentTasks = allTasks // 恢复默认
    }

}

extension Notification.Name {
    static let tasksDidChange = Notification.Name("tasksDidChange")
}

// MARK: - 全局可变任务列表

var currentTasks: [TaskItem] = {
    TaskStore.shared.load()
}() {
    didSet {
        NotificationCenter.default.post(name: .tasksDidChange, object: currentTasks)
    }
}

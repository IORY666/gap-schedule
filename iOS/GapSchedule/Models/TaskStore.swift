import Foundation
import Combine

/// 任务数据 + 应用设置（单一数据源）
final class TaskStore: ObservableObject {
    static let shared = TaskStore()
    @Published var tasks: [TaskItem] = allTasks
    private let key = "gap_tasks_v2"

    private init() {
        if let d = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([TaskItem].self, from: d), !saved.isEmpty {
            tasks = saved
        }
    }
    func save(_ t: [TaskItem]) {
        tasks = t
        if let d = try? JSONEncoder().encode(t) { UserDefaults.standard.set(d, forKey: key) }
    }
    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
        tasks = allTasks
    }
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    @Published var voiceOn: Bool {
        didSet { UserDefaults.standard.set(voiceOn, forKey: "gap_voice") }
    }
    @Published var reminderOn: Bool {
        didSet { UserDefaults.standard.set(reminderOn, forKey: "gap_remind") }
    }
    private init() {
        voiceOn = UserDefaults.standard.object(forKey: "gap_voice") as? Bool ?? true
        reminderOn = UserDefaults.standard.object(forKey: "gap_remind") as? Bool ?? true
    }
}

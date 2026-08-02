import Foundation
import Combine

/// 任务数据唯一来源（ObservableObject，SwiftUI 原生绑定）
final class TaskStore: ObservableObject {
    static let shared = TaskStore()
    @Published var tasks: [TaskItem] = defaultTasks
    private let saveKey = "gap_task_list"

    private init() { loadFromDisk() }

    func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode([TaskItem].self, from: data), !saved.isEmpty
        else { tasks = defaultTasks; return }
        tasks = saved
    }

    func save(_ t: [TaskItem]) {
        tasks = t
        if let d = try? JSONEncoder().encode(t) { UserDefaults.standard.set(d, forKey: saveKey) }
    }

    func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: saveKey)
        tasks = defaultTasks
    }
}

/// App 设置（语音开关等）
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    @Published var voiceEnabled: Bool {
        didSet { UserDefaults.standard.set(voiceEnabled, forKey: "gap_voice_enabled") }
    }
    @Published var reminderEnabled: Bool {
        didSet { UserDefaults.standard.set(reminderEnabled, forKey: "gap_reminder_enabled") }
    }

    private init() {
        voiceEnabled = UserDefaults.standard.object(forKey: "gap_voice_enabled") as? Bool ?? true
        reminderEnabled = UserDefaults.standard.object(forKey: "gap_reminder_enabled") as? Bool ?? true
    }
}

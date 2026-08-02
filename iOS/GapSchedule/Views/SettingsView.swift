import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: TaskStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("通知") {
                    Toggle(isOn: $settings.reminderOn) { Label("到点提醒", systemImage: "bell") }
                    Toggle(isOn: $settings.voiceOn) { Label("语音播报", systemImage: "waveform") }
                }
                Section("数据") {
                    Button(role: .destructive) {
                        store.reset()
                        ScheduleManager.shared.refresh()
                    } label: { Label("恢复默认任务", systemImage: "arrow.counterclockwise") }
                }
                Section { Label("版本 2.0", systemImage: "info.circle") }
            }
            .navigationTitle("设置").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } } }
        }
    }
}

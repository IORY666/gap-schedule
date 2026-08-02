import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: TaskStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("通知与提醒") {
                    Toggle(isOn: $settings.reminderEnabled) {
                        Label("到点提醒", systemImage: "bell")
                    }
                    Toggle(isOn: $settings.voiceEnabled) {
                        Label("语音播报", systemImage: "waveform")
                    }
                }

                Section("数据") {
                    Button(role: .destructive) {
                        store.resetToDefault()
                        ScheduleManager.shared.refresh()
                    } label: {
                        Label("恢复默认任务", systemImage: "arrow.counterclockwise")
                    }
                }

                Section("关于") {
                    HStack {
                        Label("版本", systemImage: "info.circle")
                        Spacer()
                        Text("1.0").foregroundColor(.secondary)
                    }
                    Label("Xiaoyi 神经网络语音", systemImage: "speaker.wave.3")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

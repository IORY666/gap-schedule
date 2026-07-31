import SwiftUI

/// Snooze 提醒弹窗（完整复刻桌面版）
struct ReminderPopupView: View {
    let task: TaskItem
    let isOnTime: Bool       // true=到点, false=预告
    @EnvironmentObject var manager: ScheduleManager
    @Environment(\.dismiss) private var dismiss

    @State private var remainSeconds = 15
    @State private var borderGlow = false

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            Text(isOnTime ? "⏰ 时间到！开始吧" : "⏰ 还有\(remainMin)分钟开始")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "f0a040"))
                .padding(.bottom, 10)

            // Emoji
            Text(task.emoji)
                .font(.system(size: 50))
                .padding(.bottom, 4)

            // 任务名
            Text(task.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 2)

            // 时间
            Text(task.timeRange)
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.5))
                .padding(.bottom, 16)

            if isOnTime {
                // 到点弹窗：只有一个按钮
                Button(action: { dismiss() }) {
                    Text("✓ 知道了")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 200, height: 40)
                        .background(Color(hex: "57d97c"))
                        .cornerRadius(20)
                }
            } else {
                // Snooze弹窗：四个按钮
                HStack(spacing: 8) {
                    snoozeButton("离开", color: Color.white.opacity(0.4)) {
                        manager.dismiss(task.id)
                        dismiss()
                    }
                    snoozeButton("5分钟后", color: Color(hex: "74c0fc")) {
                        manager.snooze(taskId: task.id, minutes: 5)
                        dismiss()
                    }
                    snoozeButton("1分钟后", color: Color(hex: "f0a040")) {
                        manager.snooze(taskId: task.id, minutes: 1)
                        dismiss()
                    }
                    snoozeButton("到点", color: Color(hex: "57d97c")) {
                        manager.snooze(taskId: task.id, minutes: max(1, remainMin))
                        dismiss()
                    }
                }
            }

            // 倒计时条
            if !isOnTime {
                ProgressView(value: Double(remainSeconds), total: 15)
                    .tint(Color(hex: "f0a040"))
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                Text("\(remainSeconds)秒后自动推迟5分钟")
                    .font(.system(size: 10))
                    .foregroundColor(Color.white.opacity(0.3))
            }
        }
        .padding(24)
        .background(Color(hex: "1a1b1e"))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderGlow ? Color(hex: "f0a040") : Color(hex: "1a1b1e"), lineWidth: 2)
                .animation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true), value: borderGlow)
        )
        .shadow(color: .black.opacity(0.5), radius: 30)
        .onAppear {
            borderGlow = true
            startCountdown()
            // 语音播报
            let mode: ReminderMode = isOnTime ? .onTime : .tenMin
            SpeechManager.shared.speakReminder(taskId: task.id, mode: mode)
        }
        .onDisappear { SpeechManager.shared.stop() }
    }

    private var remainMin: Int {
        task.startMinutes - (Calendar.current.component(.hour, from: Date()) * 60
                           + Calendar.current.component(.minute, from: Date()))
    }

    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if remainSeconds > 0 {
                remainSeconds -= 1
            } else {
                t.invalidate()
                manager.snooze(taskId: task.id, minutes: 5)
                dismiss()
            }
        }
    }

    private func snoozeButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
                .frame(minWidth: 60, idealWidth: 70)
                .padding(.vertical, 10)
                .padding(.horizontal, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
        }
    }
}

// MARK: - Hex Color

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double(rgb & 0xFF) / 255
        )
    }
}

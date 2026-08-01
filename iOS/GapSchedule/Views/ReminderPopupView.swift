import SwiftUI
import Combine

/// Snooze 提醒弹窗
struct ReminderPopupView: View {
    let task: TaskItem
    let isOnTime: Bool
    let onDismiss: () -> Void           // 替代 @Environment(\.dismiss)
    @EnvironmentObject var manager: ScheduleManager

    @State private var remainSeconds = 15
    @State private var borderGlow = false

    /// Combine 倒计时（每1秒触发）
    private let countdown = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            Text(isOnTime ? "⏰ 时间到！" : "⏰ 还有\(max(0, remainMin))分钟")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "f0a040"))
                .padding(.bottom, 10)

            Text(task.emoji)
                .font(.system(size: 50))
                .padding(.bottom, 4)

            Text(task.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 2)

            Text(task.timeRange)
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.5))
                .padding(.bottom, 16)

            if isOnTime {
                Button(action: { onDismiss() }) {
                    Text("✓ 知道了")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 200, height: 40)
                        .background(Color(hex: "57d97c"))
                        .cornerRadius(20)
                }
            } else {
                HStack(spacing: 8) {
                    snoozeBtn("离开", Color.white.opacity(0.4)) {
                        manager.dismiss(task.id)
                        onDismiss()
                    }
                    snoozeBtn("5分钟后", Color(hex: "74c0fc")) {
                        manager.snooze(taskId: task.id, minutes: 5)
                        onDismiss()
                    }
                    snoozeBtn("1分钟后", Color(hex: "f0a040")) {
                        manager.snooze(taskId: task.id, minutes: 1)
                        onDismiss()
                    }
                    snoozeBtn("到点", Color(hex: "57d97c")) {
                        manager.snooze(taskId: task.id, minutes: max(1, remainMin))
                        onDismiss()
                    }
                }
            }

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
            // 语音播报（延迟确保 AudioSession 就绪）
            let text = isOnTime ? task.nowSpeech : task.pre10Speech
            SpeechManager.shared.speak(text)
        }
        .onDisappear {
            SpeechManager.shared.stop()
        }
        .onReceive(countdown) { _ in
            guard !isOnTime else { return }
            if remainSeconds > 0 {
                remainSeconds -= 1
            } else {
                manager.snooze(taskId: task.id, minutes: 5)
                onDismiss()
            }
        }
    }

    private var remainMin: Int {
        let now = Calendar.current.component(.hour, from: Date()) * 60
                + Calendar.current.component(.minute, from: Date())
        return max(0, task.startMinutes - now)
    }

    private func snoozeBtn(_ title: String, _ color: Color, action: @escaping () -> Void) -> some View {
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

// MARK: - Hex Color Helper

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

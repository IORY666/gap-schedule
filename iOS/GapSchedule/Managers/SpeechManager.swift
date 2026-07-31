import AVFoundation

/// iOS 内置中文语音播报（比 Windows SAPI 自然得多）
final class SpeechManager {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?

    private init() {}

    /// 播报提醒文本
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.48     // 稍慢，清晰自然
        utterance.pitchMultiplier = 1.05
        utterance.volume = 0.9
        synthesizer.speak(utterance)
    }

    /// 播报任务提醒（任务ID + 模式）
    func speakReminder(taskId: Int, mode: ReminderMode) {
        guard let task = allTasks.first(where: { $0.id == taskId }) else { return }
        switch mode {
        case .tenMin:  speak(task.pre10Speech)
        case .fiveMin: speak(task.pre5Speech)
        case .onTime:  speak(task.nowSpeech)
        }
    }

    /// 停止播报
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// 播放提醒音效（bundle 中的 WAV 文件）
    func playSound(named: String) {
        guard let url = Bundle.main.url(forResource: named, withExtension: "wav") else { return }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }
}

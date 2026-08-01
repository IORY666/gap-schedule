import AVFoundation

/// iOS 语音播报管理器
final class SpeechManager: NSObject {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()
    private var hasVoice = false

    private override init() {
        super.init()
        synthesizer.delegate = self

        // 配置音频会话（允许后台播放 + 混音）
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback, mode: .default,
                options: [.duckOthers, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[Speech] AudioSession error: \(error)")
        }

        // 检查中文语音
        if let voice = AVSpeechSynthesisVoice(language: "zh-CN") {
            hasVoice = true
            print("[Speech] Voice: \(voice.name) (\(voice.language))")
        } else {
            print("[Speech] WARNING: zh-CN voice not available, using default")
        }
    }

    /// 播报提醒文本（主线程调用）
    func speak(_ text: String) {
        guard hasVoice || AVSpeechSynthesisVoice(language: "zh-CN") != nil else {
            print("[Speech] No Chinese voice, skip: \(text)")
            return
        }

        // 停止当前播报
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.05
        utterance.volume = 0.9

        DispatchQueue.main.async { [weak self] in
            self?.synthesizer.speak(utterance)
        }
    }

    func stop() {
        DispatchQueue.main.async { [weak self] in
            self?.synthesizer.stopSpeaking(at: .immediate)
        }
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("[Speech] Finished: \(utterance.speechString)")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("[Speech] Cancelled")
    }
}

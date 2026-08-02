import AVFoundation

/// 语音播报：默认任务播 edge-tts Xiaoyi mp3，自定义任务用系统 TTS
final class SpeechManager: NSObject {
    static let shared = SpeechManager()

    private let synth = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?

    private override init() {
        super.init()
        synth.delegate = self
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[Speech] AudioSession: \(error.localizedDescription)")
        }
    }

    /// 播报任务语音（mp3 优先 → TTS 回退）
    func speak(taskId: Int, mode: String) {
        // mode: "pre" | "now"
        // 尝试加载 bundle 中的 mp3
        let filename = "\(taskId)_\(mode)"
        if let url = Bundle.main.url(forResource: filename, withExtension: "mp3") {
            playMP3(url: url)
            return
        }

        // 回退到 TTS
        guard let task = defaultTasks.first(where: { $0.id == taskId }) else { return }
        let text = mode == "now" ? task.nowSpeech : task.pre5Speech
        speakTTS(text)
    }

    /// 直接播报文本（自定义任务用）
    func speakTTS(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.synth.isSpeaking { self.synth.stopSpeaking(at: .word) }
            let voice = AVSpeechSynthesisVoice(language: "zh-CN")
                ?? AVSpeechSynthesisVoice(language: "zh-Hans-CN")
                ?? AVSpeechSynthesisVoice()
            let u = AVSpeechUtterance(string: text)
            u.voice = voice; u.rate = 0.48; u.pitchMultiplier = 1.05; u.volume = 0.9
            self.synth.speak(u)
        }
    }

    func stop() {
        DispatchQueue.main.async { [weak self] in
            self?.synth.stopSpeaking(at: .immediate)
            self?.player?.stop()
        }
    }

    private func playMP3(url: URL) {
        DispatchQueue.main.async { [weak self] in
            self?.player = try? AVAudioPlayer(contentsOf: url)
            self?.player?.play()
        }
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("[Speech] TTS OK")
    }
}

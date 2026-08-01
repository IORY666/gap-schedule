import AVFoundation

/// 语音播报（全主线程操作，避免竞态）
final class SpeechManager: NSObject {
    static let shared = SpeechManager()

    private let synth = AVSpeechSynthesizer()
    private var pendingText: String?

    private override init() {
        super.init()
        synth.delegate = self
        setupAudio()
    }

    private func setupAudio() {
        do {
            // .playback 类别：忽略静音开关，确保闹钟语音总能播出来
            try AVAudioSession.sharedInstance().setCategory(
                .playback, mode: .spokenAudio,
                options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("[Speech] AudioSession ready")
        } catch {
            print("[Speech] AudioSession error: \(error.localizedDescription)")
        }
    }

    /// 播报文本（线程安全）
    func speak(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // 如果正在播，先停掉
            if self.synth.isSpeaking {
                self.synth.stopSpeaking(at: .word)
            }
            self.pendingText = text

            let voice = AVSpeechSynthesisVoice(language: "zh-CN")
                ?? AVSpeechSynthesisVoice(language: "zh-Hans-CN")
                ?? AVSpeechSynthesisVoice()

            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = voice
            utterance.rate = 0.48
            utterance.pitchMultiplier = 1.05
            utterance.volume = 0.9

            print("[Speech] Speaking: \(text) (voice: \(voice?.name ?? "default"))")
            self.synth.speak(utterance)
        }
    }

    func stop() {
        DispatchQueue.main.async { [weak self] in
            self?.pendingText = nil
            if self?.synth.isSpeaking == true {
                self?.synth.stopSpeaking(at: .immediate)
            }
        }
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        print("[Speech] OK: \(utterance.speechString)")
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didCancel utterance: AVSpeechUtterance) {
        print("[Speech] Cancelled: \(utterance.speechString)")
    }
}

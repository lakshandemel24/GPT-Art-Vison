import AVFoundation

class SpeechManager {
    static let shared = SpeechManager()
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private init() {
        setupAudioSessionForPlayback()
    }
    
    func speak(text: String, completion: @escaping () -> Void) {
        setupAudioSessionForPlayback() // Ensure audio session is configured before speaking
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "it-IT")
        utterance.rate = 0.4
        speechSynthesizer.speak(utterance)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion()
        }
    }
    
    func stopSpeaking(immediately: Bool) {
        speechSynthesizer.stopSpeaking(at: immediately ? .immediate : .word)
    }
    
    private func setupAudioSessionForPlayback() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            //print("Audio session successfully configured for playback.")
        } catch {
            //print("Failed to configure audio session for playback: \(error.localizedDescription)")
        }
    }
}

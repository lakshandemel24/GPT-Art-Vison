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
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            printAvailableAudioRoutes()
            //print("Audio session successfully configured for playback.")
        } catch {
            //print("Failed to configure audio session for playback: \(error.localizedDescription)")
        }
    }
    
    //method to print available audio routes
    private func printAvailableAudioRoutes() {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {
            print("Available output: \(output.portName) - \(output.portType.rawValue)")
        }
    }
}

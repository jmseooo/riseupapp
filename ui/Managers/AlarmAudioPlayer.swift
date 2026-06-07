import AVFoundation

final class AlarmAudioPlayer {
    static let shared = AlarmAudioPlayer()
    private var player: AVAudioPlayer?

    private init() {}

    func play() {
        guard let url = Bundle.main.url(forResource: "alarm_sound", withExtension: "caf") else {
            print("[AlarmAudioPlayer] alarm_sound.caf not found in bundle")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.play()
        } catch {
            print("[AlarmAudioPlayer] play failed: \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

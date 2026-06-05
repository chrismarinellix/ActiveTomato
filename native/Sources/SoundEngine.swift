import AVFoundation

/// Oscillator-based sound synthesis, replacing the web app's Web Audio
/// oscillators. Mixes overlapping tones with a short attack/release
/// envelope through one persistent AVAudioSourceNode.
final class SoundEngine {
    enum Wave { case sine, square, triangle }

    private struct Note {
        let freq: Double
        let wave: Wave
        let total: Int
        var remaining: Int
        var phase: Double
        let amp: Double
    }

    private let engine = AVAudioEngine()
    private var src: AVAudioSourceNode!
    private let sr: Double = 44_100
    private var notes: [Note] = []
    private var lock = os_unfair_lock()
    private var started = false

    /// Master gain (0...1).
    var masterVolume: Double = 0.5

    private let speaker = AVSpeechSynthesizer()

    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!
        src = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let out = abl[0].mData!.assumingMemoryBound(to: Float.self)

            os_unfair_lock_lock(&self.lock)
            let vol = self.masterVolume
            for frame in 0..<Int(frameCount) {
                var sample = 0.0
                for i in self.notes.indices where self.notes[i].remaining > 0 {
                    let n = self.notes[i]
                    sample += Self.shape(n.wave, n.phase) * n.amp * Self.envelope(n)
                    self.notes[i].phase += 2 * .pi * n.freq / self.sr
                    if self.notes[i].phase > 2 * .pi { self.notes[i].phase -= 2 * .pi }
                    self.notes[i].remaining -= 1
                }
                out[frame] = Float(max(-1, min(1, sample * vol)))
            }
            self.notes.removeAll { $0.remaining <= 0 }
            os_unfair_lock_unlock(&self.lock)
            return noErr
        }
        engine.attach(src)
        engine.connect(src, to: engine.mainMixerNode, format: format)
    }

    // MARK: Waveform + envelope

    private static func shape(_ w: Wave, _ phase: Double) -> Double {
        switch w {
        case .sine:     return sin(phase)
        case .square:   return sin(phase) >= 0 ? 1 : -1
        case .triangle: return 2 / .pi * asin(sin(phase))
        }
    }

    private static func envelope(_ n: Note) -> Double {
        let pos = n.total - n.remaining
        let attack = max(1, n.total / 20)
        let release = max(1, n.total / 6)
        if pos < attack { return Double(pos) / Double(attack) }
        if n.remaining < release { return Double(n.remaining) / Double(release) }
        return 1
    }

    // MARK: Playback

    private func ensureStarted() {
        guard !started else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            started = true
        } catch {
            // Audio simply stays silent if the session can't start.
        }
    }

    /// Schedule a tone. `delay` (seconds) staggers it for melodies/sequences.
    func tone(_ freq: Double, _ duration: Double, _ wave: Wave = .sine,
              amp: Double = 0.3, delay: Double = 0) {
        ensureStarted()
        let note = Note(freq: freq, wave: wave,
                        total: Int(duration * sr), remaining: Int(duration * sr),
                        phase: 0, amp: amp)
        if delay <= 0 {
            append(note)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.append(note)
            }
        }
    }

    private func append(_ note: Note) {
        os_unfair_lock_lock(&lock)
        notes.append(note)
        os_unfair_lock_unlock(&lock)
    }

    func speak(_ text: String) {
        let u = AVSpeechUtterance(string: text)
        u.rate = 0.5
        u.volume = Float(masterVolume)
        speaker.speak(u)
    }
}

//
//  VoiceRecorderManager.swift
//  AnamelDemo
//
//  Created by Joury on 05/11/1446 AH.
//


import Foundation
import AVFoundation

class VoiceRecorderManager: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    // File location
//    public var recordingUrl: URL {
//        let fileName = "recording.m4a"
//        return FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
//    }
    
    private(set) var recordingUrl: URL = FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")


    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var micLevel: Float = 0.0  // NEW: For waveform visualization

    // MARK: - Start Recording 💡
    func startRecording() {
        let fileName = UUID().uuidString + ".m4a"
        recordingUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            audioRecorder = try AVAudioRecorder(url: recordingUrl, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true

            startUpdatingMeters()
            print("Recording started at: \(recordingUrl)")
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }


    // MARK: - Stop Recording
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopUpdatingMeters()  // Stop mic level updates
        print("Recording stopped. File saved at: \(recordingUrl)")
    }

    // MARK: - Play Recording
    func playRecording() {
        print("Trying to play from: \(recordingUrl.path)")

        guard FileManager.default.fileExists(atPath: recordingUrl.path) else {
            print("Recording file not found.")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: recordingUrl)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            print("Playback started.")
        } catch {
            print("Failed to play recording: \(error.localizedDescription)")
        }
    }

    // MARK: - Stop Playback
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        print("Playback stopped.")
    }

    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        print("Playback finished.")
    }

    // MARK: - Meter Updates for Waveform
    private func startUpdatingMeters() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.audioRecorder?.updateMeters()
            self.micLevel = self.audioRecorder?.averagePower(forChannel: 0).normalizedLevel() ?? 0
        }
    }

    private func stopUpdatingMeters() {
        timer?.invalidate()
        micLevel = 0
    }

    // MARK: - Play External Audio File (e.g. from CloudKit)
    func playExternalRecording(from url: URL) {
        stopPlayback()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            print("✅ External recording playback started.")
        } catch {
            print("❌ Failed to play external recording: \(error.localizedDescription)")
        }
    }
}

// MARK: - Normalize Audio Power
private extension Float {
    func normalizedLevel() -> Float {
        let level = max(0.2, min(1, (self + 60) / 60))
        return level
    }
}

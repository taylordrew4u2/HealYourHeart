//
//  MaraVoice.swift
//  heal
//
//  Local helper for Mara's cloned voice.
//

import Foundation
import AVFoundation

@MainActor
final class MaraVoice: NSObject, AVAudioPlayerDelegate {
    static let shared = MaraVoice()

    private var cache: [String: Data] = [:]
    private var uploadedReferencePath: String?
    private var huggingFaceToken = MaraVoice.storedHuggingFaceToken()
    private var huggingFaceSpace = URL(string: "https://mrfakename-e2-f5-tts.hf.space")!
    private var player: AVAudioPlayer?
    private var onFinish: (() -> Void)?

    private override init() {
        super.init()
        activatePlaybackSession()
    }

    func play(clip name: String, ext: String = "m4a", completion: (() -> Void)? = nil) {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            completion?()
            return
        }
        play(url: url, completion: completion)
    }

    func speak(_ text: String) async throws {
        let data = try await synthesize(text)
        await withCheckedContinuation { continuation in
            play(data: data) {
                continuation.resume()
            }
        }
    }

    func prepare() async {
        guard uploadedReferencePath == nil else { return }
        uploadedReferencePath = try? await uploadReference(to: huggingFaceSpace, token: huggingFaceToken)
    }

    func synthesize(_ text: String) async throws -> Data {
        let cleaned = normalized(text)
        if let hit = cache[cleaned] {
            return hit
        }

        let data = try await synthesizeWithHuggingFace(cleaned, token: huggingFaceToken, space: huggingFaceSpace)
        cache[cleaned] = data
        return data
    }

    var referenceAudioURL: URL? {
        Bundle.main.url(forResource: "reference", withExtension: "wav")
    }

    var referenceText: String? {
        Bundle.main.url(forResource: "reference", withExtension: "txt")
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) }
    }

    func useHuggingFace(token: String, space: URL = URL(string: "https://mrfakename-e2-f5-tts.hf.space")!) {
        let cleaned = token.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(cleaned, forKey: Self.huggingFaceTokenStorageKey)
        huggingFaceToken = cleaned
        huggingFaceSpace = space
        cache.removeAll()
        uploadedReferencePath = nil
    }

    func stop() {
        player?.stop()
        onFinish?()
        onFinish = nil
    }

    private func play(url: URL, completion: (() -> Void)?) {
        guard let player = try? AVAudioPlayer(contentsOf: url) else {
            completion?()
            return
        }
        start(player, completion: completion)
    }

    private func play(data: Data, completion: (() -> Void)?) {
        guard let player = try? AVAudioPlayer(data: data) else {
            completion?()
            return
        }
        start(player, completion: completion)
    }

    private func start(_ player: AVAudioPlayer, completion: (() -> Void)?) {
        self.player?.stop()
        self.player = player
        onFinish = completion
        player.delegate = self
        activatePlaybackSession()
        player.prepareToPlay()
        if !player.play() {
            completion?()
        }
    }

    private func activatePlaybackSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }

    private func synthesizeWithHuggingFace(_ text: String, token: String, space: URL) async throws -> Data {
        if uploadedReferencePath == nil {
            uploadedReferencePath = try await uploadReference(to: space, token: token)
        }

        guard let uploadedReferencePath else {
            throw VoiceError.server("Mara's voice reference could not be prepared.")
        }

        let payload: [String: Any] = [
            "data": [
                ["path": uploadedReferencePath, "meta": ["_type": "gradio.FileData"]],
                referenceText ?? "",
                text,
                false
            ]
        ]

        var request = URLRequest(url: space.appendingPathComponent("gradio_api/call/predict"))
        request.httpMethod = "POST"
        applyAuthorization(token, to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 20

        let (callData, callResponse) = try await URLSession.shared.data(for: request)
        try validate(response: callResponse, data: callData)

        guard let eventID = (try JSONSerialization.jsonObject(with: callData) as? [String: Any])?["event_id"] as? String else {
            throw VoiceError.server("Mara's voice service did not return an event.")
        }

        var poll = URLRequest(url: space.appendingPathComponent("gradio_api/call/predict/\(eventID)"))
        applyAuthorization(token, to: &poll)
        poll.timeoutInterval = 90

        let (pollData, pollResponse) = try await URLSession.shared.data(for: poll)
        try validate(response: pollResponse, data: pollData)

        guard let audioURL = audioURL(fromServerEvents: pollData) else {
            let detail = String(data: pollData, encoding: .utf8) ?? "No audio URL returned."
            throw VoiceError.server(detail)
        }

        var download = URLRequest(url: audioURL)
        applyAuthorization(token, to: &download)
        download.timeoutInterval = 30

        let (audioData, audioResponse) = try await URLSession.shared.data(for: download)
        try validate(response: audioResponse, data: audioData)
        return audioData
    }

    private func uploadReference(to space: URL, token: String) async throws -> String {
        guard let referenceAudioURL,
              let referenceData = try? Data(contentsOf: referenceAudioURL) else {
            throw VoiceError.server("Mara's voice reference audio is missing.")
        }

        let boundary = "MaraVoiceBoundary-\(UUID().uuidString)"
        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"files\"; filename=\"reference.wav\"\r\n")
        body.appendString("Content-Type: audio/wav\r\n\r\n")
        body.append(referenceData)
        body.appendString("\r\n--\(boundary)--\r\n")

        var request = URLRequest(url: space.appendingPathComponent("gradio_api/upload"))
        request.httpMethod = "POST"
        applyAuthorization(token, to: &request)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 45

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        guard let paths = try JSONSerialization.jsonObject(with: data) as? [String],
              let firstPath = paths.first else {
            throw VoiceError.server("Mara's voice reference upload did not return a file path.")
        }
        return firstPath
    }

    private func applyAuthorization(_ token: String, to request: inout URLRequest) {
        let cleaned = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.hasPrefix("hf_"), cleaned != "hf_YOUR_TOKEN" else { return }
        request.setValue("Bearer \(cleaned)", forHTTPHeaderField: "Authorization")
    }

    private func audioURL(fromServerEvents data: Data) -> URL? {
        guard let serverEvents = String(data: data, encoding: .utf8) else { return nil }
        let dataLines = serverEvents
            .split(separator: "\n")
            .filter { $0.hasPrefix("data:") }
            .reversed()

        for line in dataLines {
            let jsonText = line.dropFirst(5).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let jsonData = jsonText.data(using: .utf8),
                  let array = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
                continue
            }

            if let urlString = array.first?["url"] as? String,
               let url = URL(string: urlString) {
                return url
            }
        }
        return nil
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw VoiceError.server(String(data: data, encoding: .utf8) ?? "Unknown voice service error")
        }
    }

    private func normalized(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .split(separator: " ")
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.onFinish?()
            self.onFinish = nil
        }
    }

    enum VoiceError: Error {
        case server(String)
    }

    private static let huggingFaceTokenStorageKey = "maraHuggingFaceToken"

    private static func storedHuggingFaceToken() -> String {
        UserDefaults.standard.string(forKey: huggingFaceTokenStorageKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}

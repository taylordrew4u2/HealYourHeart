//
//  AppleNativeServices.swift
//  heal
//
//  Apple-native implementations for voice and on-device model support.
//

import AVFoundation
import Foundation
import Speech

@MainActor
final class AppleSpeechRecognitionService {
    enum RecognitionError: LocalizedError {
        case missingUsageDescription(String)
        case unavailable
        case authorizationDenied
        case recordingUnavailable
        case noTranscript

        var errorDescription: String? {
            switch self {
            case .missingUsageDescription(let key):
                return "Missing \(key) in Info.plist. Add the usage description in Xcode target settings before enabling recording."
            case .unavailable:
                return "Speech recognition is not available right now."
            case .authorizationDenied:
                return "Speech recognition or microphone access was not granted."
            case .recordingUnavailable:
                return "The microphone could not start recording."
            case .noTranscript:
                return "No speech was captured."
            }
        }
    }

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var latestTranscript = ""

    var isRecording: Bool {
        audioEngine.isRunning
    }

    func startRecording(
        contextualStrings: [String],
        onTranscript: @escaping @MainActor (String) -> Void
    ) async throws {
        try ensureUsageDescriptionsExist()
        try await requestAuthorization()

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw RecognitionError.unavailable
        }

        recognitionTask?.cancel()
        recognitionTask = nil
        latestTranscript = ""

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.contextualStrings = contextualStrings
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let transcript = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.latestTranscript = transcript
                    onTranscript(transcript)
                }
            }

            if error != nil || result?.isFinal == true {
                Task { @MainActor in
                    self.stopAudioEngine()
                }
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            stopAudioEngine()
            throw RecognitionError.recordingUnavailable
        }
    }

    func stopRecording() async throws -> String {
        stopAudioEngine()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        let transcript = latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else {
            throw RecognitionError.noTranscript
        }
        return transcript
    }

    func cancelRecording() {
        stopAudioEngine()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }

    private func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func ensureUsageDescriptionsExist() throws {
        let requiredKeys = ["NSSpeechRecognitionUsageDescription", "NSMicrophoneUsageDescription"]
        for key in requiredKeys where Bundle.main.object(forInfoDictionaryKey: key) == nil {
            throw RecognitionError.missingUsageDescription(key)
        }
    }

    private func requestAuthorization() async throws {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            throw RecognitionError.authorizationDenied
        }

        let microphoneGranted = await AVAudioApplication.requestRecordPermission()
        guard microphoneGranted else {
            throw RecognitionError.authorizationDenied
        }
    }
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
struct AppleFoundationModelsCompanionProvider: CompanionResponding {
    /// Apple's on-device model is not present on every device. Callers check
    /// this before promising the user an on-device conversation.
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    func send(message: String, context: CompanionRequestContext) async throws -> ProviderCompanionResponse {
        let model = SystemLanguageModel.default

        switch model.availability {
        case .available:
            let instructions = HealYourHeartCopy.companionSystemInstructions(
                userName: context.userDisplayName,
                companionName: context.companionName,
                personName: context.recoveryPersonName
            )
            let session = LanguageModelSession(instructions: instructions)
            let prompt = promptText(message: message, context: context)
            let response = try await session.respond(to: prompt)
            return ProviderCompanionResponse(reply: response.content, suggestedAction: nil)
        case .unavailable:
            // No on-device model here. The caller falls back to the built-in
            // local responses rather than reaching for anything off-device.
            throw CompanionModelError.unavailable
        }
    }

    private func promptText(message: String, context: CompanionRequestContext) -> String {
        let memories = context.relevantMemories
            .map { "- [\($0.category)] \($0.subject): \($0.content)" }
            .joined(separator: "\n")

        let recent = context.recentMessages
            .suffix(8)
            .map { "\($0.role): \($0.content)" }
            .joined(separator: "\n")

        return """
        Current journey phase: \(context.journeyPhase)
        Contact status: \(context.contactStatus)
        Contact goals: \(context.contactGoals.joined(separator: ", "))

        Relevant memories:
        \(memories.isEmpty ? "None." : memories)

        Recent conversation:
        \(recent.isEmpty ? "None." : recent)

        User message:
        \(message)
        """
    }
}
#endif

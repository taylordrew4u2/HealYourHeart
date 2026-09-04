//
//  HealYourHeartServices.swift
//  heal
//
//  Service contracts and local implementations for the production build path.
//

import AVFoundation
import Foundation

struct CompanionRequestContext: Codable, Equatable {
    var userDisplayName: String
    var companionName: String
    var recoveryPersonName: String
    var relationshipType: String
    var contactStatus: String
    var contactGoals: [String]
    var journeyPhase: String
    var recentMessages: [CompanionContextMessage]
    var relevantMemories: [CompanionContextMemory]
    var recentContactEvents: [CompanionContextContactEvent]
}

struct CompanionContextMessage: Codable, Equatable, Identifiable {
    var id: UUID
    var role: String
    var content: String
    var sourceMode: String
    var createdAt: Date
}

struct CompanionContextMemory: Codable, Equatable, Identifiable {
    var id: UUID
    var category: String
    var subject: String
    var content: String
    var importance: Double
    var confidence: Double
    var sourceMessageIDs: [String]
    var isPinned: Bool
}

struct CompanionContextContactEvent: Codable, Equatable, Identifiable {
    var id: UUID
    var kind: String
    var detail: String
    var confirmedReset: Bool
    var createdAt: Date
}

struct ProviderCompanionResponse: Codable, Equatable {
    var reply: String
    var memoryChanges: [ProviderMemoryChange]
    var suggestedAction: ProviderSuggestedAction?
}

struct ProviderMemoryChange: Codable, Equatable, Identifiable {
    enum ChangeType: String, Codable {
        case add
        case update
        case delete
    }

    var id: UUID
    var type: ChangeType
    var category: String
    var subject: String
    var content: String
    var importance: Double
    var confidence: Double
    var sourceMessageIDs: [String]
}

struct ProviderSuggestedAction: Codable, Equatable {
    enum ActionType: String, Codable {
        case delayTimer
        case breathing
        case contactedMeFlow
        case slippedFlow
        case safety
    }

    var type: ActionType
    var label: String
}

protocol RemoteCompanionProviding {
    func send(message: String, context: CompanionRequestContext) async throws -> ProviderCompanionResponse
}

struct MockRemoteCompanionProvider: RemoteCompanionProviding {
    func send(message: String, context: CompanionRequestContext) async throws -> ProviderCompanionResponse {
        let lowercased = message.lowercased()

        if Self.containsAny(lowercased, words: ["kill myself", "end my life", "hurt myself", "hurt them", "suicide", "not safe"]) {
            return ProviderCompanionResponse(
                reply: "This needs human support first. If anyone is in immediate danger, call emergency services now. If you can, contact a trusted person and ask them to stay with you.",
                memoryChanges: [],
                suggestedAction: ProviderSuggestedAction(type: .safety, label: "Get immediate support")
            )
        }

        if Self.containsAny(lowercased, words: ["text", "call", "message", "reach out"]) {
            return ProviderCompanionResponse(
                reply: "Before you act, name the outcome you want. Then compare it with what has happened before when contact restarted.",
                memoryChanges: [],
                suggestedAction: ProviderSuggestedAction(type: .delayTimer, label: "Start a delay")
            )
        }

        return ProviderCompanionResponse(
            reply: "Let's separate this into fact, hope, and fear. What do you know for sure?",
            memoryChanges: [],
            suggestedAction: nil
        )
    }

    private static func containsAny(_ text: String, words: [String]) -> Bool {
        words.contains { text.contains($0) }
    }
}

protocol MemoryManaging {
    func relevantMemories(for message: String, from memories: [CompanionContextMemory]) -> [CompanionContextMemory]
    func applying(changes: [ProviderMemoryChange], to memories: [CompanionContextMemory]) -> [CompanionContextMemory]
}

struct LocalMemoryManager: MemoryManaging {
    func relevantMemories(for message: String, from memories: [CompanionContextMemory]) -> [CompanionContextMemory] {
        let lowercased = message.lowercased()
        return memories
            .filter { memory in
                memory.isPinned ||
                lowercased.contains(memory.subject.lowercased()) ||
                lowercased.contains(memory.category.lowercased())
            }
            .sorted { left, right in
                if left.isPinned != right.isPinned { return left.isPinned }
                return left.importance > right.importance
            }
            .prefix(8)
            .map { $0 }
    }

    func applying(changes: [ProviderMemoryChange], to memories: [CompanionContextMemory]) -> [CompanionContextMemory] {
        var updated = memories

        for change in changes {
            switch change.type {
            case .add:
                updated.append(
                    CompanionContextMemory(
                        id: change.id,
                        category: change.category,
                        subject: change.subject,
                        content: change.content,
                        importance: change.importance,
                        confidence: change.confidence,
                        sourceMessageIDs: change.sourceMessageIDs,
                        isPinned: false
                    )
                )
            case .update:
                if let index = updated.firstIndex(where: { $0.id == change.id }) {
                    updated[index].category = change.category
                    updated[index].subject = change.subject
                    updated[index].content = change.content
                    updated[index].importance = change.importance
                    updated[index].confidence = change.confidence
                    updated[index].sourceMessageIDs = change.sourceMessageIDs
                }
            case .delete:
                updated.removeAll { $0.id == change.id }
            }
        }

        return updated
    }
}

protocol JourneyContentProviding {
    func days(for length: Int) -> [JourneyContentDay]
}

struct JourneyContentDay: Codable, Equatable, Identifiable {
    var id: Int { number }
    var number: Int
    var title: String
    var phase: String
    var lesson: String
    var action: String
    var checkIn: String
}

struct LocalJourneyContentProvider: JourneyContentProviding {
    private let baseDays: [JourneyContentDay] = [
        JourneyContentDay(number: 1, title: "Your Fragile Moments", phase: "Stabilize", lesson: "Your nervous system is trying to protect you by making everything feel urgent.", action: "Put one glass of water and one simple food choice within reach.", checkIn: "What part of today felt most fragile?"),
        JourneyContentDay(number: 2, title: "Breathing Out", phase: "Stabilize", lesson: "Relief often starts by slowing the body before solving the story.", action: "Try four slow exhales before opening any old messages.", checkIn: "Did your body soften even a little?"),
        JourneyContentDay(number: 8, title: "Why the Silence", phase: "Cut Off and Understand", lesson: "Silence can feel like an answer, a punishment, or an invitation to chase. It may be none of those.", action: "Do not use silence as evidence of your worth today.", checkIn: "What meaning are you adding to the silence?"),
        JourneyContentDay(number: 14, title: "The Wave of the Urge", phase: "Cut Off and Understand", lesson: "An urge rises, peaks, and falls. It asks for action, but it is not the same as a decision.", action: "Delay the next contact impulse by ten minutes and stay with your companion while it passes.", checkIn: "What outcome did the urge promise you?"),
        JourneyContentDay(number: 30, title: "You Don't Need One More Answer", phase: "Untangle the Story", lesson: "Some answers would only create another question. Closure can start before certainty arrives.", action: "Choose one action that belongs only to your life.", checkIn: "What would you do tonight if no answer came?"),
        JourneyContentDay(number: 60, title: "Rebuild Self-Trust", phase: "Rebuild Self-Trust", lesson: "Trust returns through kept promises, not one grand realization.", action: "Keep one small promise to yourself before noon.", checkIn: "What did you prove to yourself today?"),
        JourneyContentDay(number: 90, title: "A Life Not Organized Around Them", phase: "Move Forward", lesson: "Moving forward does not require forgetting. It requires making your life larger than the ache.", action: "Plan one future-facing thing that has nothing to do with them.", checkIn: "Where did your attention belong today?")
    ]

    func days(for length: Int) -> [JourneyContentDay] {
        baseDays.filter { $0.number <= length }
    }
}

protocol SpeechRecognitionServicing {
    func startRecording() async throws
    func stopRecording() async throws -> String
}

struct SpeechRecognitionPlaceholderService: SpeechRecognitionServicing {
    func startRecording() async throws {}

    func stopRecording() async throws -> String {
        ""
    }
}

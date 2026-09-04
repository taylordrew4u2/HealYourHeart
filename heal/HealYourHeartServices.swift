//
//  HealYourHeartServices.swift
//  heal
//
//  Service contracts and local implementations. Apple frameworks only.
//

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

/// Implemented by whatever generates the companion's words. Today that is
/// Apple's on-device model; nothing in this app talks to a server.
protocol CompanionResponding {
    func send(message: String, context: CompanionRequestContext) async throws -> ProviderCompanionResponse
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
    func days(for length: Int) -> [JourneyContentDay] {
        JourneyLibrary.days(for: length)
    }
}

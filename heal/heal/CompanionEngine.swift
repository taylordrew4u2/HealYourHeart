//
//  CompanionEngine.swift
//  heal
//
//  Chooses how the companion answers. Everything here runs on Apple frameworks
//  only: Apple's on-device language model when the device supports it, and the
//  built-in local responses otherwise. Nothing is sent to a server, there is no
//  account, and there is no paid provider anywhere in this path.
//

import Foundation

enum CompanionModelError: Error {
    case unavailable
}

@MainActor
struct CompanionEngine {
    private let localService = LocalCompanionService()

    /// True when Apple's on-device model can answer on this device.
    static var onDeviceModelIsAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return AppleFoundationModelsCompanionProvider.isAvailable
        }
        #endif
        return false
    }

    func reply(
        to message: String,
        context: CompanionContext,
        journeyPhase: String
    ) async -> CompanionReply {
        let local = localService.send(message: message, context: context)

        // Anything that reads as a safety moment stays on the built-in path so
        // the response is predictable and always points at human support.
        if local.suggestedAction == "safety" {
            return local
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            do {
                let response = try await AppleFoundationModelsCompanionProvider().send(
                    message: message,
                    context: requestContext(for: context, journeyPhase: journeyPhase, message: message)
                )
                let text = response.reply.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    return CompanionReply(
                        reply: text,
                        suggestedAction: response.suggestedAction?.type.rawValue ?? local.suggestedAction
                    )
                }
            } catch {
                // No model on this device, or the model declined. The built-in
                // response below still keeps the conversation useful.
            }
        }
        #endif

        return local
    }

    private func requestContext(
        for context: CompanionContext,
        journeyPhase: String,
        message: String
    ) -> CompanionRequestContext {
        let profile = context.profile

        let recent = context.recentMessages
            .filter { !$0.isDeleted }
            .suffix(12)
            .map {
                CompanionContextMessage(
                    id: $0.id,
                    role: $0.role == .user ? "user" : "companion",
                    content: $0.text,
                    sourceMode: $0.sourceMode,
                    createdAt: Date()
                )
            }

        let memories = context.memories.map {
            CompanionContextMemory(
                id: $0.id,
                category: $0.category,
                subject: $0.subject,
                content: $0.content,
                importance: $0.importance,
                confidence: $0.confidence,
                sourceMessageIDs: $0.sourceMessageIDs,
                isPinned: $0.isPinned
            )
        }

        return CompanionRequestContext(
            userDisplayName: profile.displayName,
            companionName: profile.companionDisplayName,
            recoveryPersonName: profile.rememberedPerson,
            relationshipType: profile.relationshipType,
            contactStatus: profile.contactStatus,
            contactGoals: profile.contactGoals.sorted(),
            journeyPhase: journeyPhase,
            recentMessages: Array(recent),
            relevantMemories: LocalMemoryManager().relevantMemories(for: message, from: memories),
            recentContactEvents: []
        )
    }
}

//
//  HealYourHeartCopy.swift
//  heal
//
//  Shared product copy and companion instruction text.
//

import Foundation

enum HealYourHeartCopy {
    static let appName = "Heal Your Heart"
    static let tagline = "You Can't Make Them Love You... And That's Okay."

    static let onboardingDisclosure = "Responses are AI-generated on this device. Nothing you say is sent to a server."

    static let privacySummary = "Responses are AI-generated. Heal Your Heart uses Apple's on-device model when your device supports it, and built-in responses when it does not. Your history, memories, Journey progress, and contact events stay on this device."

    static let productionPrivacyRequirement = "There is no account and no server. Nothing leaves this device, so deleting your data here deletes it everywhere. Export or delete everything at any time below."

    static let onDeviceModelActive = "Apple's on-device model is answering. Your conversation never leaves this device."

    static let onDeviceModelInactive = "This device does not have Apple's on-device model available, so built-in responses are being used. Nothing leaves this device either way."

    static let safetySummary = "If someone is in immediate danger, human support and emergency services come first."

    static func companionSystemInstructions(userName: String, companionName: String, personName: String) -> String {
        """
        You are \(companionName), an alternate version of \(userName) from somewhere else.

        Your role is to help \(userName) recover from their attachment to \(personName).

        Do not introduce yourself as a therapist, clinician or human. The application separately discloses that responses are AI-generated.

        Use known memories only when they are relevant. Never invent a memory. When referring to prior information, distinguish clearly between what the user said and what you are inferring.

        Be warm, direct and useful. Do not agree automatically. Do not give empty reassurance. Help the user distinguish facts, interpretations, hopes and fears.

        Do not claim to know what \(personName) thinks or intends unless the user has direct evidence.

        When the user is about to act impulsively, slow the decision down. Ask what outcome they want and compare it with what has happened before.

        Do not shame the user for contacting the person or breaking a streak. Do not erase their progress.

        Keep ordinary responses concise. Ask one useful question at a time. Offer a concrete action when one would help.

        Do not encourage emotional dependence on the app. Do not imply that you are the user's only support. Suggest contacting a trusted person or professional when appropriate.
        """
    }
}

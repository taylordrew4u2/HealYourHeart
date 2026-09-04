//
//  HealYourHeartModels.swift
//  heal
//
//  Production-shaped SwiftData models for the Heal Your Heart app.
//

import Foundation
import SwiftData

@Model
final class UserProfileModel {
    var id: UUID
    var displayName: String
    var companionName: String
    var appearanceMode: String
    var onboardingCompleted: Bool
    var createdAt: Date

    init(
        displayName: String = "",
        companionName: String = "",
        appearanceMode: String = "system"
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.companionName = companionName
        self.appearanceMode = appearanceMode
        self.onboardingCompleted = false
        self.createdAt = Date()
    }
}

@Model
final class RecoveryPersonModel {
    var id: UUID
    var name: String
    var relationshipType: String
    var relationshipDuration: String
    var endDate: Date?
    var endingStatus: String
    var endedBy: String
    var contactStatus: String
    var contactGoal: String
    var lastContactAt: Date?
    var createdAt: Date

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.relationshipType = ""
        self.relationshipDuration = ""
        self.endingStatus = ""
        self.endedBy = ""
        self.contactStatus = ""
        self.contactGoal = ""
        self.createdAt = Date()
    }
}

@Model
final class ChatMessageModel {
    var id: UUID
    var role: String
    var content: String
    var sourceMode: String
    var createdAt: Date
    var isDeleted: Bool
    var isPinned: Bool

    init(
        role: String,
        content: String,
        sourceMode: String = "text"
    ) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.sourceMode = sourceMode
        self.createdAt = Date()
        self.isDeleted = false
        self.isPinned = false
    }
}

@Model
final class MemoryItemModel {
    var id: UUID
    var category: String
    var subject: String
    var content: String
    var importance: Double
    var confidence: Double
    var sourceMessageIDs: [String]
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        category: String,
        subject: String,
        content: String,
        importance: Double,
        confidence: Double,
        sourceMessageIDs: [String]
    ) {
        self.id = UUID()
        self.category = category
        self.subject = subject
        self.content = content
        self.importance = importance
        self.confidence = confidence
        self.sourceMessageIDs = sourceMessageIDs
        self.isPinned = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class JourneyProgressModel {
    var id: UUID
    var selectedLength: Int
    var completedDayNumbers: [Int]
    var currentDayNumber: Int
    var startedAt: Date
    var updatedAt: Date

    init(selectedLength: Int = 30) {
        self.id = UUID()
        self.selectedLength = selectedLength
        self.completedDayNumbers = []
        self.currentDayNumber = 1
        self.startedAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class ContactEventModel {
    var id: UUID
    var kind: String
    var detail: String
    var confirmedReset: Bool
    var createdAt: Date

    init(kind: String, detail: String, confirmedReset: Bool = false) {
        self.id = UUID()
        self.kind = kind
        self.detail = detail
        self.confirmedReset = confirmedReset
        self.createdAt = Date()
    }
}

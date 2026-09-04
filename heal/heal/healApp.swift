//
//  healApp.swift
//  heal
//
//  Created by Taylor Drew on 9/4/26.
//

import SwiftUI
import SwiftData

@main
struct healApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            UserProfileModel.self,
            RecoveryPersonModel.self,
            ChatMessageModel.self,
            MemoryItemModel.self,
            JourneyProgressModel.self,
            ContactEventModel.self
        ])
    }
}

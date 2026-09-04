//
//  healApp.swift
//  heal
//
//  Created by Taylor Drew on 9/4/26.
//

import SwiftUI

@main
struct healApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Storage today is on-device app storage, encoded through LocalPersistence.
// The SwiftData schema in HealYourHeartModels.swift is the shape to migrate to
// when the history grows past what app storage should hold; attach it here with
// .modelContainer(for:) at that point.

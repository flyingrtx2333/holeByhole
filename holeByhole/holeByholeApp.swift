//
//  holeByholeApp.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

@main
struct holeByholeApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GolfCourse.self,
            GolfHole.self,
            GolfVideo.self,
            VideoKeyFrame.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(localizationManager)
                .onAppear {
                    // Run data migration on app launch
                    let context = sharedModelContainer.mainContext
                    AppFileManager.shared.fixVideoPaths(in: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

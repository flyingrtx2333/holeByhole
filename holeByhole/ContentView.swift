//
//  MainTabView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("tab.home".localized)
                }
                .tag(0)
            
            CourseListView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("tab.courses".localized)
                }
                .tag(1)
            
            HoleDiaryView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("tab.diary".localized)
                }
                .tag(2)
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("tab.stats".localized)
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("tab.settings".localized)
                }
                .tag(4)
        }
        .accentColor(.green)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

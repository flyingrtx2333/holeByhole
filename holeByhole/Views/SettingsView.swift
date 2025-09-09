//
//  SettingsView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var courses: [GolfCourse]
    @Query private var holes: [GolfHole]
    @Query private var videos: [GolfVideo]
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("followSystemTheme") private var followSystemTheme = true
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingDeleteAlert = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                // Appearance Section
                Section("settings.appearance".localized) {
                    Toggle("settings.follow.system.theme".localized, isOn: $followSystemTheme)
                        .onChange(of: followSystemTheme) { _, newValue in
                            if newValue {
                                isDarkMode = false
                            }
                        }
                    
                    if !followSystemTheme {
                        Toggle("settings.dark.mode".localized, isOn: $isDarkMode)
                    }
                }
                
                // Language Section
                Section("settings.language".localized) {
                    Picker("settings.language".localized, selection: $localizationManager.currentLanguage) {
                        Text("System").tag("system")
                        Text("English").tag("en")
                        Text("简体中文").tag("zh-Hans")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: localizationManager.currentLanguage) { _, newValue in
                        localizationManager.setLanguage(newValue)
                    }
                }
                
                // Data Section
                Section("settings.data".localized) {
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundColor(.green)
                        Text("settings.courses".localized)
                        Spacer()
                        Text("\(courses.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.blue)
                        Text("settings.holes.recorded".localized)
                        Spacer()
                        Text("\(holes.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "video.fill")
                            .foregroundColor(.purple)
                        Text("settings.videos".localized)
                        Spacer()
                        Text("\(videos.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Storage Section
                Section("settings.storage".localized) {
                    StorageInfoView()
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("settings.clear.all.data".localized)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // About Section
                Section("settings.about".localized) {
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("settings.about.holebyhole".localized)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.gray)
                        Text("settings.version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("settings.title".localized)
            .preferredColorScheme(followSystemTheme ? nil : (isDarkMode ? .dark : .light))
            .alert("settings.clear.data.title".localized, isPresented: $showingDeleteAlert) {
                Button("common.cancel".localized, role: .cancel) { }
                Button("settings.delete".localized, role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("settings.clear.data.alert".localized)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
    private func clearAllData() {
        // Delete all video files and thumbnails
        for video in videos {
            // Delete video file
            AppFileManager.shared.deleteVideoFile(at: URL(fileURLWithPath: video.filePath))
            
            // Delete thumbnail file if exists
            if let thumbnailPath = video.thumbnailPath {
                AppFileManager.shared.deleteThumbnailFile(at: thumbnailPath)
            }
            
            modelContext.delete(video)
        }
        
        // Delete all holes
        for hole in holes {
            modelContext.delete(hole)
        }
        
        // Delete all courses and their photos
        for course in courses {
            // Delete course photo if exists
            if let photoPath = course.photoPath {
                AppFileManager.shared.deleteCoursePhoto(at: photoPath)
            }
            
            modelContext.delete(course)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // App Icon and Name
                    VStack(spacing: 12) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("app.name".localized)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("一洞一记")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("app.subtitle".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("about.title".localized)
                            .font(.headline)
                        
                        Text("about.description".localized)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        Text("about.features".localized)
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "video.fill", title: "about.video.recording".localized, description: "about.video.recording.desc".localized)
                            FeatureRow(icon: "chart.bar.fill", title: "about.performance.tracking".localized, description: "about.performance.tracking.desc".localized)
                            FeatureRow(icon: "map.fill", title: "about.course.management".localized, description: "about.course.management.desc".localized)
                            FeatureRow(icon: "book.fill", title: "about.personal.diary".localized, description: "about.personal.diary.desc".localized)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Version Info
                    VStack(spacing: 8) {
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("about.built.with".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("about.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StorageInfoView: View {
    @State private var storageInfo: (videosCount: Int, thumbnailsCount: Int, coursePhotosCount: Int, totalSize: Int64) = (0, 0, 0, 0)
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "internaldrive.fill")
                    .foregroundColor(.orange)
                Text("settings.storage.used".localized)
                Spacer()
                Text(formatFileSize(storageInfo.totalSize))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "video.fill")
                    .foregroundColor(.purple)
                Text("settings.video.files".localized)
                Spacer()
                Text("\(storageInfo.videosCount)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "photo.fill")
                    .foregroundColor(.blue)
                Text("settings.thumbnail.files".localized)
                Spacer()
                Text("\(storageInfo.thumbnailsCount)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.green)
                Text("settings.course.photos".localized)
                Spacer()
                Text("\(storageInfo.coursePhotosCount)")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            updateStorageInfo()
        }
        .onChange(of: localizationManager.currentLanguage) { _, _ in
            // Force view refresh when language changes
        }
    }
    
    private func updateStorageInfo() {
        storageInfo = AppFileManager.shared.getStorageInfo()
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

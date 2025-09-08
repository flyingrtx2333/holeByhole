//
//  HoleRecordDetailView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct HoleRecordDetailView: View {
    let hole: GolfHole
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditView = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: hole.holeSide == .front ? "hole.front.number".localized : "hole.back.number".localized, hole.holeNumber))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let course = hole.course {
                        Text(course.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(hole.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Score Card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("hole.record.score".localized)
                            .font(.headline)
                        
                        if let score = hole.score {
                            Text("\(score)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(scoreColor(score: score, par: hole.par))
                        } else {
                            Text("hole.record.no.score".localized)
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("hole.record.par".localized)
                            .font(.headline)
                        
                        Text("\(hole.par)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Additional Information
                if hasAdditionalInfo {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("hole.record.additional.info".localized)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            if let weather = hole.weather, !weather.isEmpty {
                                InfoRow(icon: "cloud.fill", title: "hole.record.weather".localized, value: weather)
                            }
                            
                            if let mood = hole.mood, !mood.isEmpty {
                                InfoRow(icon: "face.smiling.fill", title: "hole.record.mood".localized, value: mood)
                            }
                            
                            if let strategy = hole.strategy, !strategy.isEmpty {
                                InfoRow(icon: "brain.head.profile", title: "hole.record.strategy".localized, value: strategy)
                            }
                            
                            if let notes = hole.notes, !notes.isEmpty {
                                InfoRow(icon: "note.text", title: "hole.record.notes".localized, value: notes)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Videos Section
                if !hole.videos.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("hole.record.videos".localized)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            ForEach(hole.videos) { video in
                                VideoCard(video: video)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .navigationTitle("hole.record.detail.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("common.edit".localized) {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditHoleView(hole: hole)
        }
        .onAppear {
            // Run migration if needed
            AppFileManager.shared.fixVideoPaths(in: modelContext)
        }
    }
    
    private var hasAdditionalInfo: Bool {
        return (hole.weather?.isEmpty == false) ||
               (hole.mood?.isEmpty == false) ||
               (hole.strategy?.isEmpty == false) ||
               (hole.notes?.isEmpty == false)
    }
    
    private func scoreColor(score: Int, par: Int) -> Color {
        let difference = score - par
        switch difference {
        case ..<0: return .red // Under par
        case 0: return .green // Par
        case 1: return .orange // Bogey
        default: return .red // Double bogey or worse
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct VideoCard: View {
    let video: GolfVideo
    @Environment(\.modelContext) private var modelContext
    @State private var showingVideoPlayback = false
    @State private var thumbnailImage: UIImage?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                showingVideoPlayback = true
            }) {
            ZStack {
                // Thumbnail Image
                if let thumbnail = thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    // Placeholder when no thumbnail
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 120)
                        .cornerRadius(12)
                        .overlay(
                            VStack {
                                Image(systemName: "video.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                Text("video.no.thumbnail".localized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                }
                
                // Video play icon overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                
                // Information overlay at the bottom
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(video.clubType.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text(video.shotType.displayName)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatDuration(video.duration))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text(video.createdAt, style: .time)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Delete button
            HStack {
                Spacer()
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("common.delete".localized)
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
                .padding(.top, 4)
            }
        }
        .onAppear {
            loadThumbnail()
        }
        .fullScreenCover(isPresented: $showingVideoPlayback) {
            VideoPlaybackView(video: video)
        }
        .alert("common.delete".localized, isPresented: $showingDeleteAlert) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("common.delete".localized, role: .destructive) {
                deleteVideo()
            }
        } message: {
            Text("video.delete.confirmation".localized)
        }
    }
    
    private func loadThumbnail() {
        guard let thumbnailPath = video.thumbnailPath else { return }
        thumbnailImage = AppFileManager.shared.loadThumbnail(from: thumbnailPath)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func deleteVideo() {
        // Delete video file
        AppFileManager.shared.deleteVideoFile(at: URL(fileURLWithPath: video.filePath))
        
        // Delete thumbnail file if exists
        if let thumbnailPath = video.thumbnailPath {
            AppFileManager.shared.deleteThumbnailFile(at: thumbnailPath)
        }
        
        // Delete from database
        modelContext.delete(video)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete video: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        HoleRecordDetailView(hole: GolfHole(holeNumber: 1, holeSide: .front, par: 4))
    }
    .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

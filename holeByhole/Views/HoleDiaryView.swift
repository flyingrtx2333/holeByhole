//
//  HoleDiaryView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct HoleDiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GolfHole.createdAt, order: .reverse) private var allHoles: [GolfHole]
    @State private var selectedFilter: DiaryFilter = .all
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var holesToDelete: IndexSet = []
    
    var filteredHoles: [GolfHole] {
        var holes = allHoles
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .withVideos:
            holes = holes.filter { !$0.videos.isEmpty }
        case .withScores:
            holes = holes.filter { $0.score != nil }
        case .recent:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            holes = holes.filter { $0.createdAt >= oneWeekAgo }
        }
        
        // Apply search
        if !searchText.isEmpty {
            holes = holes.filter { hole in
                hole.course?.name.localizedCaseInsensitiveContains(searchText) == true ||
                hole.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                hole.weather?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return holes
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter Picker
                Picker("diary.filter".localized, selection: $selectedFilter) {
                    ForEach(DiaryFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if filteredHoles.isEmpty {
                    EmptyDiaryView(filter: selectedFilter)
                } else {
                    List {
                        ForEach(filteredHoles) { hole in
                            NavigationLink(destination: HoleRecordDetailView(hole: hole)) {
                                HoleDiaryRowView(hole: hole)
                            }
                        }
                        .onDelete(perform: showDeleteConfirmation)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("diary.title".localized)
            .searchable(text: $searchText, prompt: "diary.search.entries".localized)
            .alert("common.delete".localized, isPresented: $showingDeleteAlert) {
                Button("common.cancel".localized, role: .cancel) { }
                Button("common.delete".localized, role: .destructive) {
                    deleteHoles(offsets: holesToDelete)
                }
            } message: {
                Text("diary.delete.confirmation".localized)
            }
        }
    }
    
    private func showDeleteConfirmation(offsets: IndexSet) {
        holesToDelete = offsets
        showingDeleteAlert = true
    }
    
    private func deleteHoles(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let hole = filteredHoles[index]
                
                // Delete associated video files and thumbnails
                for video in hole.videos {
                    // Delete video file
                    AppFileManager.shared.deleteVideoFile(at: URL(fileURLWithPath: video.filePath))
                    
                    // Delete thumbnail file if exists
                    if let thumbnailPath = video.thumbnailPath {
                        AppFileManager.shared.deleteThumbnailFile(at: thumbnailPath)
                    }
                    
                    modelContext.delete(video)
                }
                
                // Delete the hole
                modelContext.delete(hole)
            }
            
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete holes: \(error)")
            }
        }
    }
}

enum DiaryFilter: CaseIterable {
    case all, withVideos, withScores, recent
    
    var displayName: String {
        switch self {
        case .all: return "diary.filter.all".localized
        case .withVideos: return "diary.filter.videos".localized
        case .withScores: return "diary.filter.scores".localized
        case .recent: return "diary.filter.recent".localized
        }
    }
}

struct HoleDiaryRowView: View {
    let hole: GolfHole
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(String(format: hole.holeSide == .front ? "hole.front.number".localized : "hole.back.number".localized, hole.holeNumber))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let course = hole.course {
                        Text("• \(course.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let score = hole.score {
                    Text(String(format: "diary.score.format".localized, score, hole.par))
                        .font(.subheadline)
                        .foregroundColor(scoreColor(score: score, par: hole.par))
                } else {
                    Text(String(format: "diary.par.format".localized, hole.par))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let notes = hole.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(hole.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if !hole.videos.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "video.fill")
                                .font(.caption2)
                            Text("\(hole.videos.count)")
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let score = hole.score {
                    Text("\(score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(score: score, par: hole.par))
                } else {
                    Text("—")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Text(String(format: "diary.par.format".localized, hole.par))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
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

struct EmptyDiaryView: View {
    let filter: DiaryFilter
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("diary.no.entries.title".localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(emptyMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all:
            return "diary.empty.message.all".localized
        case .withVideos:
            return "diary.empty.message.videos".localized
        case .withScores:
            return "diary.empty.message.scores".localized
        case .recent:
            return "diary.empty.message.recent".localized
        }
    }
}

#Preview {
    HoleDiaryView()
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

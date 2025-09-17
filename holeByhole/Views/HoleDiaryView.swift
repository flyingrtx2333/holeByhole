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
    @Query private var allCourses: [GolfCourse]
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedFilter: DiaryFilter = .all
    @State private var selectedScoreFilter: ScoreFilter = .all
    @State private var selectedCourseFilter: GolfCourse? = nil
    @State private var showingDeleteAlert = false
    @State private var holesToDelete: IndexSet = []
    
    var filteredHoles: [GolfHole] {
        var holes = allHoles
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .byScore:
            holes = holes.filter { hole in
                guard let myStrokes = hole.myStrokes else { return false }
                let score = myStrokes - hole.par
                return scoreFilterMatches(score: score)
            }
        case .byCourse:
            if let selectedCourse = selectedCourseFilter {
                holes = holes.filter { $0.course?.id == selectedCourse.id }
            }
        }
        
        return holes
    }
    
    private func scoreFilterMatches(score: Int) -> Bool {
        switch selectedScoreFilter {
        case .all:
            return true
        case .eagle:
            return score <= -2
        case .birdie:
            return score == -1
        case .par:
            return score == 0
        case .bogey:
            return score == 1
        case .doubleBogey:
            return score == 2
        case .worse:
            return score > 2
        }
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
                
                // Secondary Filter
                if selectedFilter == .byScore {
                    Picker("diary.filter.by.score".localized, selection: $selectedScoreFilter) {
                        ForEach(ScoreFilter.allCases, id: \.self) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                } else if selectedFilter == .byCourse {
                    Picker("diary.filter.by.course".localized, selection: $selectedCourseFilter) {
                        Text("diary.course.filter.all".localized).tag(nil as GolfCourse?)
                        ForEach(allCourses, id: \.id) { course in
                            Text(course.name).tag(course as GolfCourse?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                }
                
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
            .onChange(of: localizationManager.currentLanguage) { _, _ in
                // Force view refresh when language changes
            }
            .id(localizationManager.currentLanguage) // Force view refresh when language changes
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
    case all, byScore, byCourse
    
    var displayName: String {
        switch self {
        case .all: return "diary.filter.all".localized
        case .byScore: return "diary.filter.by.score".localized
        case .byCourse: return "diary.filter.by.course".localized
        }
    }
}

enum ScoreFilter: CaseIterable {
    case all, eagle, birdie, par, bogey, doubleBogey, worse
    
    var displayName: String {
        switch self {
        case .all: return "diary.filter.all".localized
        case .eagle: return "diary.score.filter.eagle".localized
        case .birdie: return "diary.score.filter.birdie".localized
        case .par: return "diary.score.filter.par".localized
        case .bogey: return "diary.score.filter.bogey".localized
        case .doubleBogey: return "diary.score.filter.double.bogey".localized
        case .worse: return "diary.score.filter.worse".localized
        }
    }
}

struct HoleDiaryRowView: View {
    let hole: GolfHole
    @StateObject private var localizationManager = LocalizationManager.shared
    
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
                
                if let myStrokes = hole.myStrokes {
                    Text(String(format: "diary.score.format".localized, myStrokes, hole.par))
                        .font(.subheadline)
                        .foregroundColor(scoreColor(score: myStrokes, par: hole.par))
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
                    Text(hole.createdAt.formattedDate)
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
                if let myStrokes = hole.myStrokes {
                    Text("\(myStrokes)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(score: myStrokes, par: hole.par))
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
        .id(localizationManager.currentLanguage) // Force view refresh when language changes
    }
    
}

struct EmptyDiaryView: View {
    let filter: DiaryFilter
    @StateObject private var localizationManager = LocalizationManager.shared
    
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
        .id(localizationManager.currentLanguage) // Force view refresh when language changes
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all:
            return "diary.empty.message.all".localized
        case .byScore:
            return "diary.empty.message.scores".localized
        case .byCourse:
            return "diary.empty.message.all".localized
        }
    }
}

#Preview {
    HoleDiaryView()
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

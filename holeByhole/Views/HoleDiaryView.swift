//
//  HoleDiaryView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData
import AVKit
import AVFoundation

struct HoleDiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GolfHole.createdAt, order: .reverse) private var allHoles: [GolfHole]
    @Query private var allCourses: [GolfCourse]
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedFilter: DiaryFilter = .all
    @State private var selectedScoreFilter: ScoreFilter = .all
    @State private var selectedCourseFilter: GolfCourse? = nil
    @State private var showingDeleteAlert = false
    @State private var holesToDelete: [GolfHole] = []
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showingFilterMenu = false
    
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
            VStack(spacing: 0) {
                if filteredHoles.isEmpty {
                    EmptyDiaryView(filter: selectedFilter)
                } else {
                    // Card Carousel
                    GeometryReader { geometry in
                        DiaryCardCarouselView(
                            holes: filteredHoles,
                            currentIndex: $currentIndex,
                            dragOffset: $dragOffset,
                            onVideoTap: { video in
                                // 视频在卡片内播放，不需要设置全屏
                            },
                            onDelete: { hole in
                                holesToDelete = [hole]
                                showingDeleteAlert = true
                            }
                        )
                    }
                    .clipped()
                }
            }
            .navigationTitle("diary.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Primary Filter Section
                        Section("diary.filter".localized) {
                            ForEach(DiaryFilter.allCases, id: \.self) { filter in
                                Button(action: {
                                    selectedFilter = filter
                                    currentIndex = 0
                                    dragOffset = 0
                                }) {
                                    HStack {
                                        Text(filter.displayName)
                                        if selectedFilter == filter {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Score Filter Section (only when byScore is selected)
                        if selectedFilter == .byScore {
                            Section("diary.filter.by.score".localized) {
                                ForEach(ScoreFilter.allCases, id: \.self) { filter in
                                    Button(action: {
                                        selectedScoreFilter = filter
                                        currentIndex = 0
                                        dragOffset = 0
                                    }) {
                                        HStack {
                                            Text(filter.displayName)
                                            if selectedScoreFilter == filter {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Course Filter Section (only when byCourse is selected)
                        if selectedFilter == .byCourse {
                            Section("diary.filter.by.course".localized) {
                                Button(action: {
                                    selectedCourseFilter = nil
                                    currentIndex = 0
                                    dragOffset = 0
                                }) {
                                    HStack {
                                        Text("diary.course.filter.all".localized)
                                        if selectedCourseFilter == nil {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                
                                ForEach(allCourses, id: \.id) { course in
                                    Button(action: {
                                        selectedCourseFilter = course
                                        currentIndex = 0
                                        dragOffset = 0
                                    }) {
                                        HStack {
                                            Text(course.name)
                                            if selectedCourseFilter?.id == course.id {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                    }
                }
            }
            .onChange(of: localizationManager.currentLanguage) { _, _ in
                // Force view refresh when language changes
            }
            .id(localizationManager.currentLanguage)
            .alert("common.delete".localized, isPresented: $showingDeleteAlert) {
                Button("common.cancel".localized, role: .cancel) { }
                Button("common.delete".localized, role: .destructive) {
                    deleteHoles()
                }
            } message: {
                Text("diary.delete.confirmation".localized)
            }
        }
    }
    
    private func deleteHoles() {
        withAnimation {
            for hole in holesToDelete {
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
        holesToDelete = []
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

// MARK: - Card Carousel View
struct DiaryCardCarouselView: View {
    let holes: [GolfHole]
    @Binding var currentIndex: Int
    @Binding var dragOffset: CGFloat
    let onVideoTap: (GolfVideo) -> Void
    let onDelete: (GolfHole) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.8
            let cardSpacing: CGFloat = 20
            let sideCardScale: CGFloat = 0.85
            
            HStack(spacing: cardSpacing) {
                ForEach(Array(holes.enumerated()), id: \.element.id) { index, hole in
                     DiaryCardView(
                         hole: hole,
                         isCenter: index == currentIndex,
                         onVideoTap: onVideoTap,
                         onDelete: onDelete
                     )
                    .frame(width: cardWidth)
                    .scaleEffect(index == currentIndex ? 1.0 : sideCardScale)
                    .opacity(index == currentIndex ? 1.0 : 0.7)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentIndex)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: dragOffset)
                }
            }
            .offset(x: -CGFloat(currentIndex) * (cardWidth + cardSpacing) + (geometry.size.width - cardWidth) / 2 + dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            if value.translation.width > threshold && currentIndex > 0 {
                                currentIndex -= 1
                            } else if value.translation.width < -threshold && currentIndex < holes.count - 1 {
                                currentIndex += 1
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Individual Card View
struct DiaryCardView: View {
    let hole: GolfHole
    let isCenter: Bool
    let onVideoTap: (GolfVideo) -> Void
    let onDelete: (GolfHole) -> Void
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var isPlayingVideo = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Video Preview Section
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 200)
                
                if let firstVideo = hole.videos.first {
                    VideoPreviewView(video: firstVideo, isPlaying: $isPlayingVideo)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("diary.card.no.video".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Video count badge
                if hole.videos.count > 1 {
                    VStack {
                        HStack {
                            Spacer()
                            Text(String(format: "diary.card.videos.count".localized, hole.videos.count))
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .padding(.top, 12)
                                .padding(.trailing, 12)
                        }
                        Spacer()
                    }
                }
                
                // Play/Pause button overlay
                if !hole.videos.isEmpty {
                    Button(action: {
                        isPlayingVideo.toggle()
                    }) {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: isPlayingVideo ? "pause.fill" : "play.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .offset(x: isPlayingVideo ? 0 : 2)
                            )
                    }
                    .scaleEffect(isCenter ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.3), value: isCenter)
                    .animation(.easeInOut(duration: 0.2), value: isPlayingVideo)
                }
            }
            
            // Card Information Section
            VStack(spacing: 16) {
                // Header with hole info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: hole.holeSide == .front ? "hole.front.number".localized : "hole.back.number".localized, hole.holeNumber))
                            .font(.custom("Bradley Hand", size: 20).weight(.bold))
                            .foregroundColor(.primary)
                        
                        if let course = hole.course {
                            Text(course.name)
                                .font(.custom("Bradley Hand", size: 14).weight(.medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if let myStrokes = hole.myStrokes {
                            Text("\(myStrokes)")
                                .font(.custom("Bradley Hand", size: 28).weight(.bold))
                                .foregroundColor(scoreColor(score: myStrokes, par: hole.par))
                        } else {
                            Text("—")
                                .font(.custom("Bradley Hand", size: 28).weight(.bold))
                                .foregroundColor(.secondary)
                        }
                        
                        Text(String(format: "diary.card.par".localized + " %d", hole.par))
                            .font(.custom("Bradley Hand", size: 12).weight(.medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Information Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    InfoCardItem(
                        icon: "calendar",
                        title: "diary.card.date".localized,
                        value: hole.createdAt.formattedDate
                    )
                    
                    InfoCardItem(
                        icon: "cloud.sun",
                        title: "diary.card.weather".localized,
                        value: hole.weather ?? "diary.card.no.weather".localized
                    )
                    
                    InfoCardItem(
                        icon: "face.smiling",
                        title: "diary.card.mood".localized,
                        value: hole.mood ?? "diary.card.no.mood".localized
                    )
                    
                    InfoCardItem(
                        icon: "target",
                        title: "diary.card.strategy".localized,
                        value: hole.strategy ?? "diary.card.no.strategy".localized
                    )
                }
                
                // Notes Section
                if let notes = hole.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.secondary)
                            Text("diary.card.notes".localized)
                                .font(.custom("Bradley Hand", size: 14).weight(.medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Text(notes)
                            .font(.custom("Bradley Hand", size: 16).weight(.regular))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        onDelete(hole)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("common.delete".localized)
                        }
                        .font(.custom("Bradley Hand", size: 14).weight(.medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: HoleRecordDetailView(hole: hole)) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                            Text("common.edit".localized)
                        }
                        .font(.custom("Bradley Hand", size: 14).weight(.medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onChange(of: isCenter) { _, newIsCenter in
            // 当卡片不再是中心时，停止视频播放
            if !newIsCenter && isPlayingVideo {
                isPlayingVideo = false
            }
        }
        .id(localizationManager.currentLanguage)
    }
}

// MARK: - Info Card Item
struct InfoCardItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.system(size: 16))
            
            Text(title)
                .font(.custom("Bradley Hand", size: 12).weight(.medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.custom("Bradley Hand", size: 14).weight(.semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Video Preview View
struct VideoPreviewView: View {
    let video: GolfVideo
    @Binding var isPlaying: Bool
    @State private var thumbnailImage: UIImage?
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            if isPlaying, let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                        player.seek(to: .zero)
                    }
            } else {
                // 显示缩略图
                if let thumbnailImage = thumbnailImage {
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
            }
        }
        .onAppear {
            loadThumbnail()
            setupPlayer()
        }
        .onTapGesture {
            togglePlayback()
        }
    }
    
    private func loadThumbnail() {
        guard thumbnailImage == nil else { return }
        
        if let thumbnailPath = video.thumbnailPath,
           let image = UIImage(contentsOfFile: thumbnailPath) {
            thumbnailImage = image
        } else {
            // Generate thumbnail from video
            let videoURL = URL(fileURLWithPath: video.filePath)
            generateThumbnail(from: videoURL) { image in
                DispatchQueue.main.async {
                    self.thumbnailImage = image
                }
            }
        }
    }
    
    private func generateThumbnail(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
            if let cgImage = image {
                completion(UIImage(cgImage: cgImage))
            } else {
                completion(nil)
            }
        }
    }
    
    private func setupPlayer() {
        let videoURL = URL(fileURLWithPath: video.filePath)
        player = AVPlayer(url: videoURL)
    }
    
    private func togglePlayback() {
        isPlaying.toggle()
        
        if isPlaying {
            if player == nil {
                setupPlayer()
            }
        } else {
            player?.pause()
            player?.seek(to: .zero)
        }
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
                .font(.custom("Bradley Hand", size: 22).weight(.semibold))
            
            Text(emptyMessage)
                .font(.custom("Bradley Hand", size: 16))
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

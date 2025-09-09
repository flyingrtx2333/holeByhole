//
//  HoleRecordDetailView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData
import AVFoundation
import UIKit

struct HoleRecordDetailView: View {
    let hole: GolfHole
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditView = false
    @State private var showingVideoRecording = false
    @State private var showingVideoSelection = false
    @State private var showingActionSheet = false
    
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
                    
                    if let round = hole.round {
                        Text(round.displayName)
                            .font(.subheadline)
                            .foregroundColor(.blue)
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
                        
                        if let myStrokes = hole.myStrokes {
                            Text("\(myStrokes)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(scoreColor(score: myStrokes, par: hole.par))
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("hole.record.videos".localized)
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if !hole.videos.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            ForEach(hole.videos) { video in
                                VideoCard(video: video)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        Text("hole.record.no.videos".localized)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                
                // Add Video Button Section
                VStack(spacing: 12) {
                    Button(action: {
                        showingActionSheet = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "video.fill")
                                .font(.title2)
                            Text("hole.record.add.video".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
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
        .fullScreenCover(isPresented: $showingVideoRecording) {
            VideoRecordingView(
                course: hole.course ?? GolfCourse(name: "Unknown Course"),
                holeNumber: hole.holeNumber,
                holeSide: hole.holeSide ?? (hole.holeNumber <= 9 ? .front : .back),
                clubType: .driver,
                shotType: .tee,
                round: hole.round,
                existingHole: hole
            )
        }
        .sheet(isPresented: $showingVideoSelection) {
            VideoSelectionView(hole: hole)
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("hole.record.add.video.options".localized),
                buttons: [
                    .default(Text("hole.record.record.new".localized)) {
                        showingVideoRecording = true
                    },
                    .default(Text("hole.record.select.existing".localized)) {
                        showingVideoSelection = true
                    },
                    .cancel(Text("common.cancel".localized))
                ]
            )
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

struct VideoSelectionView: View {
    let hole: GolfHole
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVideoURL: URL?
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedClubType: ClubType = .driver
    @State private var selectedShotType: ShotType = .tee
    @State private var showingVideoDetails = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("hole.record.select.video.message".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("hole.record.select.from.photos".localized)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                if showingVideoDetails {
                    VStack(spacing: 20) {
                        // Club Type Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("recording.setup.club.type".localized)
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                ForEach(ClubType.allCases, id: \.self) { club in
                                    Button(action: {
                                        selectedClubType = club
                                    }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: clubIcon(for: club))
                                                .font(.title2)
                                            Text(club.displayName)
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedClubType == club ? Color.green : Color(.systemGray6))
                                        .foregroundColor(selectedClubType == club ? .white : .primary)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // Shot Type Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("recording.setup.shot.type".localized)
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(ShotType.allCases, id: \.self) { shotType in
                                    Button(action: {
                                        selectedShotType = shotType
                                    }) {
                                        HStack {
                                            Image(systemName: shotIcon(for: shotType))
                                            Text(shotType.displayName)
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(selectedShotType == shotType ? Color.blue : Color(.systemGray6))
                                        .foregroundColor(selectedShotType == shotType ? .white : .primary)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // Import Button
                        Button(action: {
                            if let videoURL = selectedVideoURL {
                                importVideo(from: videoURL)
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("hole.record.import.video".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("hole.record.select.video.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            VideoPickerView { url in
                selectedVideoURL = url
                if url != nil {
                    showingVideoDetails = true
                }
            }
        }
        .alert("hole.record.import.error".localized, isPresented: $showingAlert) {
            Button("common.ok".localized) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func importVideo(from url: URL) {
        do {
            // Create a new GolfVideo record
            let fileName = "imported_\(UUID().uuidString).mp4"
            let newVideo = GolfVideo(
                fileName: fileName,
                filePath: url.path,
                duration: 0, // Will be updated after processing
                clubType: selectedClubType, // Use user selected values
                shotType: selectedShotType,
                hole: hole
            )
            
            // Copy video file to app's documents directory
            let documentsPath = AppFileManager.shared.videosPath
            let destinationFileName = "\(UUID().uuidString).mp4"
            let destinationURL = documentsPath.appendingPathComponent(destinationFileName)
            
            try FileManager.default.copyItem(at: url, to: destinationURL)
            newVideo.filePath = destinationURL.path
            newVideo.fileName = destinationFileName
            
            // Generate thumbnail
            if let thumbnail = AppFileManager.shared.generateThumbnail(from: destinationURL) {
                let thumbnailFileName = "\(UUID().uuidString).jpg"
                let thumbnailURL = AppFileManager.shared.thumbnailsPath.appendingPathComponent(thumbnailFileName)
                
                if let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8) {
                    try thumbnailData.write(to: thumbnailURL)
                    newVideo.thumbnailPath = thumbnailURL.path
                }
            }
            
            // Get video duration
            let asset = AVAsset(url: destinationURL)
            let duration = CMTimeGetSeconds(asset.duration)
            newVideo.duration = duration
            
            // Save to database
            modelContext.insert(newVideo)
            try modelContext.save()
            
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    private func clubIcon(for club: ClubType) -> String {
        switch club {
        case .driver: return "figure.golf"
        case .wood: return "tree.fill"
        case .iron: return "hammer.fill"
        case .wedge: return "triangle.fill"
        case .putter: return "circle.fill"
        case .hybrid: return "plus.circle.fill"
        }
    }
    
    private func shotIcon(for shotType: ShotType) -> String {
        switch shotType {
        case .tee: return "flag.fill"
        case .fairway: return "leaf.fill"
        case .approach: return "target"
        case .chip: return "arrow.up.circle.fill"
        case .putt: return "circle.circle.fill"
        case .bunker: return "mountain.2.fill"
        }
    }
}

struct VideoPickerView: UIViewControllerRepresentable {
    let onVideoSelected: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPickerView
        
        init(_ parent: VideoPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.onVideoSelected(videoURL)
            } else {
                parent.onVideoSelected(nil)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onVideoSelected(nil)
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationView {
        HoleRecordDetailView(hole: GolfHole(holeNumber: 1, holeSide: .front, par: 4))
    }
    .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

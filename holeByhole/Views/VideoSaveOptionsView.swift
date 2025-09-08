//
//  VideoSaveOptionsView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import AVFoundation
import Photos
import SwiftData

struct VideoSaveOptionsView: View {
    let videoURL: URL
    let course: GolfCourse
    let holeNumber: Int
    let holeSide: HoleSide
    let clubType: ClubType
    let shotType: ShotType
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var thumbnailImage: UIImage?
    @State private var selectedThumbnailTime: Double = 0
    @State private var videoDuration: Double = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Video Preview
                if let thumbnail = thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .onTapGesture {
                            // Allow user to select different thumbnail
                            selectThumbnail()
                        }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(
                            ProgressView()
                        )
                }
                
                // Thumbnail Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("video.save.thumbnail".localized)
                        .font(.headline)
                    
                    HStack {
                        Text("video.save.tap.to.select".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("video.save.auto.select".localized) {
                            selectThumbnail()
                        }
                        .font(.caption)
                    }
                }
                
                // Video Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("video.save.information".localized)
                        .font(.headline)
                    
                    InfoRow(icon: "video.fill", title: "video.save.duration".localized, value: formatDuration(videoDuration))
                    InfoRow(icon: "flag.fill", title: "video.save.hole".localized, value: "\(holeNumber)")
                    InfoRow(icon: "map.fill", title: "video.save.course".localized, value: course.name)
                    InfoRow(icon: "figure.golf", title: "video.save.club".localized, value: clubType.displayName)
                    InfoRow(icon: "target", title: "video.save.shot".localized, value: shotType.displayName)
                }
                
                Spacer()
                
                // Save Options
                VStack(spacing: 12) {
                    Button(action: {
                        saveToAppOnly()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("video.save.app.only".localized)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSaving)
                    
                    Button(action: {
                        saveToAppAndPhotos()
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("video.save.app.photos".localized)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSaving)
                }
            }
            .padding()
            .navigationTitle("video.save.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadVideoInfo()
            }
            .alert("common.error".localized, isPresented: $showingAlert) {
                Button("common.ok".localized) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadVideoInfo() {
        let asset = AVAsset(url: videoURL)
        videoDuration = CMTimeGetSeconds(asset.duration)
        selectedThumbnailTime = videoDuration / 2 // Default to middle of video
        
        generateThumbnail(at: selectedThumbnailTime)
    }
    
    private func generateThumbnail(at time: Double) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        
        let time = CMTime(seconds: time, preferredTimescale: 600)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            thumbnailImage = UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
        }
    }
    
    private func selectThumbnail() {
        // For now, just select a random time
        let randomTime = Double.random(in: 0...videoDuration)
        selectedThumbnailTime = randomTime
        generateThumbnail(at: randomTime)
    }
    
    private func saveToAppOnly() {
        saveVideo(saveToPhotos: false)
    }
    
    private func saveToAppAndPhotos() {
        saveVideo(saveToPhotos: true)
    }
    
    private func saveVideo(saveToPhotos: Bool) {
        isSaving = true
        
        // Save to Photos if requested
        if saveToPhotos {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoURL)
                    }) { success, error in
                        DispatchQueue.main.async {
                            if let error = error {
                                self.alertMessage = String(format: "video.save.failed.photos".localized, error.localizedDescription)
                                self.showingAlert = true
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.alertMessage = "video.save.photos.denied".localized
                        self.showingAlert = true
                    }
                }
            }
        }
        
        // Save to app database
        saveToDatabase()
    }
    
    private func saveToDatabase() {
        // Create or find the hole
        let hole = findOrCreateHole()
        
        // Create video record
        let fileName = videoURL.lastPathComponent
        let video = GolfVideo(
            fileName: fileName,
            filePath: videoURL.path,
            duration: videoDuration,
            clubType: clubType,
            shotType: shotType,
            hole: hole
        )
        
        // Save thumbnail if available
        if let thumbnail = thumbnailImage {
            let thumbnailURL = AppFileManager.shared.saveThumbnail(thumbnail)
            video.thumbnailPath = thumbnailURL?.path
        }
        
        modelContext.insert(video)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = String(format: "video.save.failed.database".localized, error.localizedDescription)
            showingAlert = true
        }
        
        isSaving = false
    }
    
    private func findOrCreateHole() -> GolfHole {
        // Try to find existing hole for this course and hole number
        let descriptor = FetchDescriptor<GolfHole>(
            predicate: #Predicate<GolfHole> { hole in
                hole.holeNumber == holeNumber
            }
        )
        
        // Filter by course manually since the predicate is having issues with optional relationships
        if let existingHoles = try? modelContext.fetch(descriptor) {
            for hole in existingHoles {
                if hole.course?.id == course.id {
                    return hole
                }
            }
        }
        
        // Create new hole
        let newHole = GolfHole(holeNumber: holeNumber, holeSide: holeSide, par: 4, course: course)
        modelContext.insert(newHole)
        return newHole
    }
    
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    VideoSaveOptionsView(
        videoURL: URL(fileURLWithPath: "/tmp/sample.mov"),
        course: GolfCourse(name: "Sample Course"),
        holeNumber: 1,
        holeSide: .front,
        clubType: .driver,
        shotType: .tee
    )
}

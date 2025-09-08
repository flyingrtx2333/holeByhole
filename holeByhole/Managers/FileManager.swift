//
//  FileManager.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import Foundation
import UIKit
import SwiftData

class AppFileManager {
    static let shared = AppFileManager()
    
    private init() {}
    
    // MARK: - Directory Paths
    
    private var appSupportPath: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
    
    var videosPath: URL {
        let path = appSupportPath.appendingPathComponent("Videos")
        try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        return path
    }
    
    var thumbnailsPath: URL {
        let path = appSupportPath.appendingPathComponent("Thumbnails")
        try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        return path
    }
    
    // MARK: - Video File Management
    
    func generateVideoFileURL() -> URL {
        let fileName = "golf_video_\(Date().timeIntervalSince1970).mov"
        return videosPath.appendingPathComponent(fileName)
    }
    
    func saveThumbnail(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let fileName = "thumbnail_\(Date().timeIntervalSince1970).jpg"
        let fileURL = thumbnailsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save thumbnail: \(error)")
            return nil
        }
    }
    
    func loadThumbnail(from path: String) -> UIImage? {
        let thumbnailURL = URL(fileURLWithPath: path)
        guard let imageData = try? Data(contentsOf: thumbnailURL) else { return nil }
        return UIImage(data: imageData)
    }
    
    func getMostRecentVideoFile() -> URL? {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: videosPath, includingPropertiesForKeys: [.creationDateKey], options: [])
            let videoFiles = files.filter { $0.pathExtension == "mov" }
            
            return videoFiles.max(by: { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 < date2
            })
        } catch {
            print("Error getting most recent video file: \(error)")
            return nil
        }
    }
    
    // MARK: - File Cleanup
    
    func deleteVideoFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    func deleteThumbnailFile(at path: String) {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Data Migration
    
    func fixVideoPaths(in modelContext: ModelContext) {
        print("🔧 Starting video path migration...")
        
        // Get all videos from database
        let descriptor = FetchDescriptor<GolfVideo>()
        guard let videos = try? modelContext.fetch(descriptor) else {
            print("❌ Failed to fetch videos from database")
            return
        }
        
        print("🔍 Found \(videos.count) videos in database")
        
        var updatedCount = 0
        
        for video in videos {
            let oldPath = video.filePath
            let oldThumbnailPath = video.thumbnailPath
            
            // Check if the old path contains a different Application ID
            if oldPath.contains("/Application/") && !oldPath.contains(appSupportPath.path) {
                // Extract filename from old path
                let fileName = URL(fileURLWithPath: oldPath).lastPathComponent
                let newVideoPath = videosPath.appendingPathComponent(fileName).path
                
                // Check if file exists at new location
                if FileManager.default.fileExists(atPath: newVideoPath) {
                    video.filePath = newVideoPath
                    print("✅ Updated video path: \(fileName)")
                    updatedCount += 1
                } else {
                    print("❌ Video file not found at new location: \(fileName)")
                }
            }
            
            // Fix thumbnail path if needed
            if let oldThumbnailPath = oldThumbnailPath,
               oldThumbnailPath.contains("/Application/") && !oldThumbnailPath.contains(appSupportPath.path) {
                let thumbnailFileName = URL(fileURLWithPath: oldThumbnailPath).lastPathComponent
                let newThumbnailPath = thumbnailsPath.appendingPathComponent(thumbnailFileName).path
                
                // Check if thumbnail exists at new location
                if FileManager.default.fileExists(atPath: newThumbnailPath) {
                    video.thumbnailPath = newThumbnailPath
                    print("✅ Updated thumbnail path: \(thumbnailFileName)")
                } else {
                    print("❌ Thumbnail file not found at new location: \(thumbnailFileName)")
                }
            }
        }
        
        // Save changes
        do {
            try modelContext.save()
            print("✅ Successfully migrated \(updatedCount) video paths")
        } catch {
            print("❌ Failed to save migrated paths: \(error)")
        }
    }
    
    // MARK: - Debug Methods
    
    func debugFilePaths() {
        print("🔍 AppFileManager Debug Info:")
        print("📁 App Support Path: \(appSupportPath.path)")
        print("📁 Videos Path: \(videosPath.path)")
        print("📁 Thumbnails Path: \(thumbnailsPath.path)")
        
        // List all video files
        do {
            let videoFiles = try FileManager.default.contentsOfDirectory(at: videosPath, includingPropertiesForKeys: nil, options: [])
            print("📹 Video files found: \(videoFiles.count)")
            for file in videoFiles {
                print("  - \(file.lastPathComponent)")
            }
        } catch {
            print("❌ Error listing video files: \(error)")
        }
        
        // List all thumbnail files
        do {
            let thumbnailFiles = try FileManager.default.contentsOfDirectory(at: thumbnailsPath, includingPropertiesForKeys: nil, options: [])
            print("🖼️ Thumbnail files found: \(thumbnailFiles.count)")
            for file in thumbnailFiles {
                print("  - \(file.lastPathComponent)")
            }
        } catch {
            print("❌ Error listing thumbnail files: \(error)")
        }
    }
    
    // MARK: - Storage Info
    
    func getStorageInfo() -> (videosCount: Int, thumbnailsCount: Int, totalSize: Int64) {
        var videosCount = 0
        var thumbnailsCount = 0
        var totalSize: Int64 = 0
        
        // Count videos
        if let videoFiles = try? FileManager.default.contentsOfDirectory(at: videosPath, includingPropertiesForKeys: [.fileSizeKey], options: []) {
            videosCount = videoFiles.count
            for file in videoFiles {
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        // Count thumbnails
        if let thumbnailFiles = try? FileManager.default.contentsOfDirectory(at: thumbnailsPath, includingPropertiesForKeys: [.fileSizeKey], options: []) {
            thumbnailsCount = thumbnailFiles.count
            for file in thumbnailFiles {
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        return (videosCount, thumbnailsCount, totalSize)
    }
}

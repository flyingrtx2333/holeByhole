//
//  VideoPlaybackView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import AVFoundation
import SwiftData

struct VideoPlaybackView: View {
    let video: GolfVideo
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var playerManager = VideoPlayerManager()
    @State private var playbackSpeed: Float = 1.0
    @State private var showingKeyFrameEditor = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isPlaying = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Video Player
                VideoPlayerView(player: playerManager.player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .background(Color.black)
                    .onTapGesture {
                        togglePlayPause()
                    }
                
                // Controls
                VStack(spacing: 16) {
                    // Progress Bar
                    VStack(spacing: 8) {
                        Slider(value: $currentTime, in: 0...duration) { editing in
                            if !editing {
                                seekToTime(currentTime)
                            }
                        }
                        .accentColor(.green)
                        
                        HStack {
                            Text(formatTime(currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formatTime(duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Playback Controls
                    HStack(spacing: 30) {
                        // Speed Control
                        Menu {
                            Button("0.25x") { setPlaybackSpeed(0.25) }
                            Button("0.5x") { setPlaybackSpeed(0.5) }
                            Button("1x") { setPlaybackSpeed(1.0) }
                            Button("1.25x") { setPlaybackSpeed(1.25) }
                            Button("1.5x") { setPlaybackSpeed(1.5) }
                            Button("2x") { setPlaybackSpeed(2.0) }
                        } label: {
                            HStack {
                                Image(systemName: "speedometer")
                                Text("\(playbackSpeed, specifier: "%.2f")x")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Play/Pause Button
                        Button(action: togglePlayPause) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                        }
                        
                        // Key Frame Button
                        Button(action: {
                            addKeyFrame()
                        }) {
                            Image(systemName: "bookmark.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Key Frames
                    if !video.keyFrames.isEmpty {
                        KeyFramesView(keyFrames: video.keyFrames, onKeyFrameTap: { keyFrame in
                            seekToTime(keyFrame.timestamp)
                        }, onKeyFrameDelete: { keyFrame in
                            deleteKeyFrame(keyFrame)
                        })
                    }
                }
                .padding()
            }
            .navigationTitle("video.playback.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("video.key.frames".localized) {
                        showingKeyFrameEditor = true
                    }
                }
            }
        }
        .onAppear {
            setupVideo()
        }
        .onDisappear {
            playerManager.cleanup()
        }
        .sheet(isPresented: $showingKeyFrameEditor) {
            KeyFrameEditorView(video: video)
        }
    }
    
    private func setupVideo() {
        let url = URL(fileURLWithPath: video.filePath)
        playerManager.loadVideo(url: url)
        duration = video.duration
        
        // Set up timer for progress updates
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            currentTime = playerManager.currentTime
            isPlaying = playerManager.isPlaying
        }
    }
    
    private func togglePlayPause() {
        if isPlaying {
            playerManager.pause()
        } else {
            playerManager.play()
        }
    }
    
    private func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        playerManager.setPlaybackSpeed(speed)
    }
    
    private func seekToTime(_ time: Double) {
        playerManager.seekTo(time: time)
        currentTime = time
    }
    
    private func addKeyFrame() {
        let keyFrame = VideoKeyFrame(
            timestamp: currentTime,
            description: "Key Frame at \(formatTime(currentTime))",
            video: video
        )
        
        modelContext.insert(keyFrame)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save key frame: \(error)")
        }
    }
    
    private func deleteKeyFrame(_ keyFrame: VideoKeyFrame) {
        modelContext.delete(keyFrame)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete key frame: \(error)")
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)
        
        DispatchQueue.main.async {
            playerLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            playerLayer.frame = uiView.bounds
        }
    }
}

struct KeyFramesView: View {
    let keyFrames: [VideoKeyFrame]
    let onKeyFrameTap: (VideoKeyFrame) -> Void
    let onKeyFrameDelete: (VideoKeyFrame) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("video.key.frames".localized)
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(keyFrames.sorted(by: { $0.timestamp < $1.timestamp })) { keyFrame in
                        VStack(spacing: 4) {
                            Button(action: {
                                onKeyFrameTap(keyFrame)
                            }) {
                                VStack(spacing: 4) {
                                    Text(formatTime(keyFrame.timestamp))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Text(keyFrame.frameDescription)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(8)
                                .frame(width: 80)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                onKeyFrameDelete(keyFrame)
                            }) {
                                Image(systemName: "trash")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationView {
        VideoPlaybackView(video: GolfVideo(
            fileName: "sample.mov",
            filePath: "/tmp/sample.mov",
            duration: 30.0,
            clubType: .driver,
            shotType: .tee
        ))
    }
}

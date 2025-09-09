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
    @State private var showingKeyFrameEdit = false
    @State private var editingKeyFrame: VideoKeyFrame?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Full Screen Video Player
                VideoPlayerView(player: playerManager.player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .onTapGesture {
                        togglePlayPause()
                    }
                
                // Controls Overlay
                VStack(spacing: 0) {
                    // Key Frames on Timeline
                    if !video.keyFrames.isEmpty {
                        KeyFramesTimelineView(
                            keyFrames: video.keyFrames,
                            currentTime: currentTime,
                            duration: duration,
                            onKeyFrameTap: { keyFrame in
                                seekToTime(keyFrame.timestamp)
                            },
                            onKeyFrameEdit: { keyFrame in
                                editKeyFrame(keyFrame)
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
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
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
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
                    .padding()
                }
                .background(Color(.systemBackground))
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
        .sheet(isPresented: $showingKeyFrameEdit) {
            if let keyFrame = editingKeyFrame {
                EditKeyFrameView(keyFrame: keyFrame)
            }
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
    
    private func editKeyFrame(_ keyFrame: VideoKeyFrame) {
        editingKeyFrame = keyFrame
        showingKeyFrameEdit = true
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

struct KeyFramesTimelineView: View {
    let keyFrames: [VideoKeyFrame]
    let currentTime: Double
    let duration: Double
    let onKeyFrameTap: (VideoKeyFrame) -> Void
    let onKeyFrameEdit: (VideoKeyFrame) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("video.key.frames".localized)
                .font(.headline)
            
            ZStack(alignment: .topLeading) {
                // Timeline background
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                
                // Key frame markers
                ForEach(keyFrames.sorted(by: { $0.timestamp < $1.timestamp })) { keyFrame in
                    let position = CGFloat(keyFrame.timestamp / duration)
                    
                    VStack(spacing: 2) {
                        // Key frame marker
                        Button(action: {
                            onKeyFrameTap(keyFrame)
                        }) {
                            VStack(spacing: 2) {
                                Text(keyFrame.frameDescription)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .cornerRadius(4)
                                
                                Image(systemName: "bookmark.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .offset(x: (UIScreen.main.bounds.width - 32) * position - 20)
                        
                        // Edit button
                        Button(action: {
                            onKeyFrameEdit(keyFrame)
                        }) {
                            Image(systemName: "pencil")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .offset(x: (UIScreen.main.bounds.width - 32) * position - 20)
                    }
                }
            }
            .frame(height: 50)
        }
    }
}

struct EditKeyFrameView: View {
    let keyFrame: VideoKeyFrame
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var description: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(keyFrame: VideoKeyFrame) {
        self.keyFrame = keyFrame
        self._description = State(initialValue: keyFrame.frameDescription)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("video.key.frame.edit".localized)) {
                    TextField("video.key.frame.description".localized, text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(footer: Text("video.key.frame.edit.note".localized)) {
                    EmptyView()
                }
            }
            .navigationTitle("video.key.frame.edit.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        saveKeyFrame()
                    }
                    .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("common.error".localized, isPresented: $showingAlert) {
                Button("common.ok".localized) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveKeyFrame() {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedDescription.isEmpty else {
            alertMessage = "video.key.frame.description.required".localized
            showingAlert = true
            return
        }
        
        keyFrame.frameDescription = trimmedDescription
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "video.key.frame.save.failed".localized
            showingAlert = true
        }
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

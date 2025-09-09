//
//  VideoRecordingView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import AVFoundation
import Photos

struct VideoRecordingView: View {
    let course: GolfCourse
    let holeNumber: Int
    let holeSide: HoleSide
    let clubType: ClubType
    let shotType: ShotType
    let round: GolfRound?
    let existingHole: GolfHole? // 可选的现有球洞记录
    
    @Environment(\.modelContext) private var modelContext
    
    init(course: GolfCourse, holeNumber: Int, holeSide: HoleSide, clubType: ClubType, shotType: ShotType, round: GolfRound?, existingHole: GolfHole?) {
        self.course = course
        self.holeNumber = holeNumber
        self.holeSide = holeSide
        self.clubType = clubType
        self.shotType = shotType
        self.round = round
        self.existingHole = existingHole
        
        // 初始化状态变量
        self._currentHoleNumber = State(initialValue: holeNumber)
        self._currentHoleSide = State(initialValue: holeSide)
        self._currentClubType = State(initialValue: clubType)
        self._currentShotType = State(initialValue: shotType)
    }
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var cameraManager = CameraManager()
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingSaveOptions = false
    @State private var recordedVideoURL: URL?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPermissionAlert = false
    @State private var isProcessingVideo = false
    @State private var processingTimer: Timer?
    
    // 可调整的参数
    @State private var currentHoleNumber: Int
    @State private var currentHoleSide: HoleSide
    @State private var currentClubType: ClubType
    @State private var currentShotType: ShotType
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreviewView(session: cameraManager.captureSession)
                .ignoresSafeArea()
            
            VStack {
                // Top Info Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: currentHoleSide == .front ? "hole.front.number".localized : "hole.back.number".localized, currentHoleNumber))
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(course.name)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(currentClubType.displayName)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(currentShotType.displayName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .onTapGesture {
                    showingSettings = true
                }
                
                Spacer()
                
                // Recording Duration or Processing Status
                if isRecording {
                    Text(formatDuration(recordingDuration))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                } else if isProcessingVideo {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("video.processing".localized)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Bottom Controls
                HStack(spacing: 40) {
                    // Switch Camera Button
                    Button(action: {
                        cameraManager.switchCamera()
                    }) {
                        Image(systemName: "camera.rotate")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    // Record Button
                    Button(action: {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color.red : Color.white)
                                .frame(width: 80, height: 80)
                            
                            if isRecording {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .frame(width: 30, height: 30)
                            } else {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 60, height: 60)
                            }
                        }
                    }
                    
                    // Close Button
                    Button(action: {
                        if isRecording {
                            stopRecording()
                        }
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            cameraManager.setupCamera()
            
            // Check permission after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !cameraManager.hasPermission {
                    showingPermissionAlert = true
                }
            }
        }
        .onDisappear {
            if isRecording {
                stopRecording()
            }
            processingTimer?.invalidate()
            processingTimer = nil
            cameraManager.stopSession()
        }
        .alert("video.recording.error".localized, isPresented: $showingAlert) {
            Button("common.ok".localized) { }
        } message: {
            Text(alertMessage)
        }
        .alert("camera.permission.required".localized, isPresented: $showingPermissionAlert) {
            Button("settings".localized) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("common.cancel".localized) {
                dismiss()
            }
        } message: {
            Text("camera.permission.message".localized)
        }
        .sheet(isPresented: $showingSaveOptions) {
            if let videoURL = recordedVideoURL {
                VideoSaveOptionsView(
                    videoURL: videoURL,
                    course: course,
                    holeNumber: currentHoleNumber,
                    holeSide: currentHoleSide,
                    clubType: currentClubType,
                    shotType: currentShotType,
                    round: round,
                    existingHole: existingHole
                )
            }
        }
        .sheet(isPresented: $showingSettings) {
            RecordingSettingsView(
                holeNumber: $currentHoleNumber,
                holeSide: $currentHoleSide,
                clubType: $currentClubType,
                shotType: $currentShotType
            )
        }
    }
    
    private func startRecording() {
        cameraManager.startRecording { url in
            DispatchQueue.main.async {
                self.isProcessingVideo = false
                self.processingTimer?.invalidate()
                self.processingTimer = nil
                self.recordedVideoURL = url
                self.showingSaveOptions = true
            }
        } onError: { error in
            DispatchQueue.main.async {
                self.isProcessingVideo = false
                self.processingTimer?.invalidate()
                self.processingTimer = nil
                self.alertMessage = String(format: "video.recording.failed.message".localized, error.localizedDescription)
                self.showingAlert = true
            }
        }
        
        isRecording = true
        recordingDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }
    }
    
    private func stopRecording() {
        // Ensure minimum recording time (1 second)
        if recordingDuration < 1.0 {
            print("⚠️ Recording too short (\(recordingDuration)s), waiting for minimum duration...")
            DispatchQueue.main.asyncAfter(deadline: .now() + (1.0 - recordingDuration)) {
                self.performStopRecording()
            }
        } else {
            performStopRecording()
        }
    }
    
    private func performStopRecording() {
        print("🛑 Performing stop recording...")
        cameraManager.stopRecording()
        isRecording = false
        isProcessingVideo = true
        timer?.invalidate()
        timer = nil
        
        // Set a timeout for processing (5 seconds)
        processingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            DispatchQueue.main.async {
                if self.isProcessingVideo {
                    print("⚠️ Processing timeout, checking for video file manually...")
                    self.checkForVideoFileManually()
                }
            }
        }
        
        // The save options will be shown automatically when the recording delegate
        // calls the onSuccess callback in startRecording()
    }
    
    private func checkForVideoFileManually() {
        // Try to find the most recent video file using AppFileManager
        if let mostRecentVideo = AppFileManager.shared.getMostRecentVideoFile() {
            print("📹 Found video file manually: \(mostRecentVideo)")
            isProcessingVideo = false
            processingTimer?.invalidate()
            processingTimer = nil
            recordedVideoURL = mostRecentVideo
            showingSaveOptions = true
        } else {
            print("❌ No video file found")
            isProcessingVideo = false
            processingTimer?.invalidate()
            processingTimer = nil
            alertMessage = "video.processing.timeout".localized
            showingAlert = true
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, milliseconds)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Store the preview layer in the context
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let previewLayer = context.coordinator.previewLayer {
                previewLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

struct RecordingSettingsView: View {
    @Binding var holeNumber: Int
    @Binding var holeSide: HoleSide
    @Binding var clubType: ClubType
    @Binding var shotType: ShotType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Hole Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("recording.setup.hole.number".localized)
                        .font(.headline)
                    
                    // Hole Side Selection
                    Picker("Hole Side", selection: $holeSide) {
                        ForEach(HoleSide.allCases, id: \.self) { side in
                            Text(side.displayName).tag(side)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Hole Number Selection
                    Picker("Hole", selection: $holeNumber) {
                        ForEach(1...9, id: \.self) { hole in
                            Text(String(format: holeSide == .front ? "hole.front.number".localized : "hole.back.number".localized, hole))
                                .tag(hole)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                }
                
                // Club Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("recording.setup.club.type".localized)
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(ClubType.allCases, id: \.self) { club in
                            Button(action: {
                                clubType = club
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: clubIcon(for: club))
                                        .font(.title2)
                                    Text(club.displayName)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(clubType == club ? Color.green : Color(.systemGray6))
                                .foregroundColor(clubType == club ? .white : .primary)
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
                                self.shotType = shotType
                            }) {
                                HStack {
                                    Image(systemName: shotIcon(for: shotType))
                                    Text(shotType.displayName)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(self.shotType == shotType ? Color.blue : Color(.systemGray6))
                                .foregroundColor(self.shotType == shotType ? .white : .primary)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("recording.settings.title".localized)
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

#Preview {
    VideoRecordingView(
        course: GolfCourse(name: "Sample Course"),
        holeNumber: 1,
        holeSide: .front,
        clubType: .driver,
        shotType: .tee,
        round: nil,
        existingHole: nil
    )
}

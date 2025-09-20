//
//  CameraManager.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import AVFoundation
import UIKit

class CameraManager: NSObject, ObservableObject {
    let captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var currentCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    private var backCamera: AVCaptureDevice?
    private var isBackCamera = true
    private var videoInput: AVCaptureDeviceInput?
    private var currentRecordingDelegate: VideoRecordingDelegate?
    
    @Published var isSessionRunning = false
    @Published var hasPermission = false
    @Published var currentZoomFactor: CGFloat = 1.0
    @Published var maxZoomFactor: CGFloat = 1.0
    
    override init() {
        super.init()
        setupCameras()
    }
    
    func setupCamera() {
        checkPermissions()
    }
    
    private func setupCameras() {
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return
        }
        
        self.backCamera = backCamera
        self.frontCamera = frontCamera
        self.currentCamera = backCamera
        
        // 设置最大变焦倍数
        self.maxZoomFactor = min(backCamera.activeFormat.videoMaxZoomFactor, 10.0)
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasPermission = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.hasPermission = granted
                    if granted {
                        self.setupSession()
                    }
                }
            }
        case .denied, .restricted:
            hasPermission = false
        @unknown default:
            hasPermission = false
        }
    }
    
    private func setupSession() {
        guard hasPermission else { return }
        
        captureSession.beginConfiguration()
        
        // Set session preset
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        // Add video input
        guard let currentCamera = currentCamera else {
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: currentCamera)
            self.videoInput = videoInput
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
        } catch {
            print("Error creating video input: \(error)")
            captureSession.commitConfiguration()
            return
        }
        
        // Add video output
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // Configure video settings
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        
        captureSession.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.captureSession.isRunning
            }
        }
    }
    
    func switchCamera() {
        guard let frontCamera = frontCamera, let backCamera = backCamera else { return }
        guard isSessionRunning else { return }
        
        captureSession.beginConfiguration()
        
        // Remove current input
        if let currentInput = videoInput {
            captureSession.removeInput(currentInput)
        }
        
        // Switch camera
        isBackCamera.toggle()
        currentCamera = isBackCamera ? backCamera : frontCamera
        
        // 更新最大变焦倍数
        updateMaxZoomFactor()
        currentZoomFactor = 1.0
        
        // Add new input
        do {
            let newInput = try AVCaptureDeviceInput(device: currentCamera!)
            self.videoInput = newInput
            
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
            }
        } catch {
            print("Error switching camera: \(error)")
            captureSession.commitConfiguration()
            return
        }
        
        captureSession.commitConfiguration()
    }
    
    func startRecording(onSuccess: @escaping (URL) -> Void, onError: @escaping (Error) -> Void) {
        guard isSessionRunning else {
            print("❌ Camera session is not running")
            onError(NSError(domain: "CameraManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Camera session is not running"]))
            return
        }
        
        guard videoOutput.isRecording == false else {
            print("❌ Already recording")
            onError(NSError(domain: "CameraManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Already recording"]))
            return
        }
        
        let fileURL = AppFileManager.shared.generateVideoFileURL()
        
        print("🎬 Starting recording to: \(fileURL)")
        print("📹 Video output is recording: \(videoOutput.isRecording)")
        print("📹 Session is running: \(captureSession.isRunning)")
        
        // Create and retain the delegate
        currentRecordingDelegate = VideoRecordingDelegate(
            onSuccess: onSuccess,
            onError: onError
        )
        
        videoOutput.startRecording(to: fileURL, recordingDelegate: currentRecordingDelegate!)
        
        // Check if recording actually started
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("📹 Recording status after 0.5s: \(self.videoOutput.isRecording)")
        }
    }
    
    func stopRecording() {
        print("🛑 Stopping recording...")
        print("📹 Video output is recording before stop: \(videoOutput.isRecording)")
        videoOutput.stopRecording()
        print("📹 Video output is recording after stop: \(videoOutput.isRecording)")
        
        // Clear the delegate after stopping
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.currentRecordingDelegate = nil
        }
    }
    
    func stopSession() {
        captureSession.stopRunning()
        isSessionRunning = false
    }
    
    // MARK: - 变焦功能
    func setZoomFactor(_ zoomFactor: CGFloat) {
        guard let camera = currentCamera else { return }
        
        let clampedZoom = max(1.0, min(zoomFactor, maxZoomFactor))
        
        do {
            try camera.lockForConfiguration()
            camera.videoZoomFactor = clampedZoom
            camera.unlockForConfiguration()
            
            DispatchQueue.main.async {
                self.currentZoomFactor = clampedZoom
            }
        } catch {
            print("Error setting zoom factor: \(error)")
        }
    }
    
    func zoomIn() {
        let newZoom = min(currentZoomFactor * 1.2, maxZoomFactor)
        setZoomFactor(newZoom)
    }
    
    func zoomOut() {
        let newZoom = max(currentZoomFactor / 1.2, 1.0)
        setZoomFactor(newZoom)
    }
    
    func resetZoom() {
        setZoomFactor(1.0)
    }
    
    func updateMaxZoomFactor() {
        guard let camera = currentCamera else { return }
        maxZoomFactor = min(camera.activeFormat.videoMaxZoomFactor, 10.0)
    }
}

class VideoRecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    private let onSuccess: (URL) -> Void
    private let onError: (Error) -> Void
    
    init(onSuccess: @escaping (URL) -> Void, onError: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("Recording finished. URL: \(outputFileURL), Error: \(error?.localizedDescription ?? "None")")
        if let error = error {
            onError(error)
        } else {
            onSuccess(outputFileURL)
        }
    }
}

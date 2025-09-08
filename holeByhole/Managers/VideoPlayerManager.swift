//
//  VideoPlayerManager.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import AVFoundation
import Combine

class VideoPlayerManager: ObservableObject {
    let player = AVPlayer()
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupPlayer()
    }
    
    deinit {
        cleanup()
    }
    
    private func setupPlayer() {
        // Observe player status
        player.publisher(for: \.timeControlStatus)
            .sink { [weak self] status in
                DispatchQueue.main.async {
                    self?.isPlaying = status == .playing
                }
            }
            .store(in: &cancellables)
        
        // Add time observer
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
        }
    }
    
    func loadVideo(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        
        // Observe duration
        playerItem.publisher(for: \.duration)
            .sink { [weak self] duration in
                DispatchQueue.main.async {
                    self?.duration = CMTimeGetSeconds(duration)
                }
            }
            .store(in: &cancellables)
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func seekTo(time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime)
    }
    
    func setPlaybackSpeed(_ speed: Float) {
        player.rate = speed
    }
    
    func cleanup() {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        cancellables.removeAll()
        player.pause()
    }
}

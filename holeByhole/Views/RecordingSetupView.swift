//
//  RecordingSetupView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct RecordingSetupView: View {
    let course: GolfCourse
    let round: GolfRound
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedHole = 1
    @State private var selectedHoleSide: HoleSide = .front
    @State private var selectedClub: ClubType = .driver
    @State private var selectedShotType: ShotType = .tee
    @State private var showingVideoRecording = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                
                // Round Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("recording.setup.round.info".localized)
                        .font(.headline)
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text("recording.setup.course".localized)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(course.name)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("recording.setup.round".localized)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(round.displayName)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Hole Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("recording.setup.hole.number".localized)
                        .font(.headline)
                    
                    // Hole Side Selection
                    Picker("Hole Side", selection: $selectedHoleSide) {
                        ForEach(HoleSide.allCases, id: \.self) { side in
                            Text(side.displayName).tag(side)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Hole Number Selection
                    Picker("Hole", selection: $selectedHole) {
                        ForEach(1...9, id: \.self) { hole in
                            Text(String(format: selectedHoleSide == .front ? "hole.front.number".localized : "hole.back.number".localized, hole))
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
                                selectedClub = club
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: clubIcon(for: club))
                                        .font(.title2)
                                    Text(club.displayName)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedClub == club ? Color.green : Color(.systemGray6))
                                .foregroundColor(selectedClub == club ? .white : .primary)
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
                
                Spacer()
                
                // Start Recording Button
                Button(action: {
                    showingVideoRecording = true
                }) {
                    HStack {
                        Image(systemName: "video.fill")
                        Text("recording.setup.start.recording".localized)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("recording.setup.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingVideoRecording) {
                VideoRecordingView(
                    course: course,
                    holeNumber: selectedHole,
                    holeSide: selectedHoleSide,
                    clubType: selectedClub,
                    shotType: selectedShotType,
                    round: round,
                    existingHole: nil
                )
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
    RecordingSetupView(
        course: GolfCourse(name: "Sample Course"),
        round: GolfRound(roundNumber: 1, course: GolfCourse(name: "Sample Course"))
    )
    .modelContainer(for: [GolfCourse.self, GolfRound.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

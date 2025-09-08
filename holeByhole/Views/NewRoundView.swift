//
//  NewRoundView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct NewRoundView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var courses: [GolfCourse]
    
    @State private var selectedCourse: GolfCourse?
    @State private var selectedHole = 1
    @State private var selectedHoleSide: HoleSide = .front
    @State private var selectedClub: ClubType = .driver
    @State private var selectedShotType: ShotType = .tee
    @State private var showingCourseSelection = false
    @State private var showingVideoRecording = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Course Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("new.round.select.course".localized)
                        .font(.headline)
                    
                    Button(action: {
                        showingCourseSelection = true
                    }) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text(selectedCourse?.name ?? "new.round.no.course".localized)
                                .foregroundColor(selectedCourse == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // Hole Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("new.round.hole.number".localized)
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
                    Text("new.round.club.type".localized)
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
                    Text("new.round.shot.type".localized)
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
                    validateAndStartRecording()
                }) {
                    HStack {
                        Image(systemName: "video.fill")
                        Text("new.round.start.recording".localized)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedCourse == nil ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("new.round.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCourseSelection) {
                CourseSelectionView(selectedCourse: $selectedCourse)
            }
            .fullScreenCover(isPresented: $showingVideoRecording) {
                if let course = selectedCourse {
                    VideoRecordingView(
                        course: course,
                        holeNumber: selectedHole,
                        holeSide: selectedHoleSide,
                        clubType: selectedClub,
                        shotType: selectedShotType
                    )
                }
            }
            .alert("validation.error".localized, isPresented: $showingValidationAlert) {
                Button("common.ok".localized) { }
            } message: {
                Text(validationMessage)
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
    
    private func validateAndStartRecording() {
        guard let course = selectedCourse else {
            validationMessage = "new.round.validation.no.course".localized
            showingValidationAlert = true
            return
        }
        
        // Additional validations can be added here if needed
        // For example, checking if hole number is valid, etc.
        
        showingVideoRecording = true
    }
}

#Preview {
    NewRoundView()
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

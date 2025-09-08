//
//  NewHoleView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct NewHoleView: View {
    let course: GolfCourse
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var holeNumber = 1
    @State private var holeSide: HoleSide = .front
    @State private var par = 4
    @State private var score: Int?
    @State private var notes = ""
    @State private var weather = ""
    @State private var mood = ""
    @State private var strategy = ""
    @State private var showingVideoRecording = false
    @State private var selectedClub: ClubType = .driver
    @State private var selectedShotType: ShotType = .tee
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("hole.information".localized)) {
                    Picker("hole.side".localized, selection: $holeSide) {
                        ForEach(HoleSide.allCases, id: \.self) { side in
                            Text(side.displayName).tag(side)
                        }
                    }
                    
                    Picker("hole.number.label".localized, selection: $holeNumber) {
                        ForEach(1...9, id: \.self) { hole in
                            Text(String(format: holeSide == .front ? "hole.front.number".localized : "hole.back.number".localized, hole)).tag(hole)
                        }
                    }
                    
                    Picker("courses.par".localized, selection: $par) {
                        ForEach(3...5, id: \.self) { parValue in
                            Text(String(format: "par.number".localized, parValue)).tag(parValue)
                        }
                    }
                    
                    HStack {
                        Text("hole.score".localized)
                        Spacer()
                        TextField("hole.score".localized, value: $score, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("new.round.shot.type".localized)) {
                    Picker("new.round.club.type".localized, selection: $selectedClub) {
                        ForEach(ClubType.allCases, id: \.self) { club in
                            Text(club.displayName).tag(club)
                        }
                    }
                    
                    Picker("new.round.shot.type".localized, selection: $selectedShotType) {
                        ForEach(ShotType.allCases, id: \.self) { shotType in
                            Text(shotType.displayName).tag(shotType)
                        }
                    }
                }
                
                Section(header: Text("Additional Information")) {
                    TextField("hole.weather".localized, text: $weather)
                    TextField("hole.mood".localized, text: $mood)
                    TextField("hole.strategy".localized, text: $strategy)
                    
                    TextField("hole.notes".localized, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(action: {
                        showingVideoRecording = true
                    }) {
                        HStack {
                            Image(systemName: "video.fill")
                            Text("hole.record.video".localized)
                        }
                        .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("hole.new".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        saveHole()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingVideoRecording) {
                VideoRecordingView(
                    course: course,
                    holeNumber: holeNumber,
                    holeSide: holeSide,
                    clubType: selectedClub,
                    shotType: selectedShotType
                )
            }
        }
    }
    
    private func saveHole() {
        let newHole = GolfHole(holeNumber: holeNumber, holeSide: holeSide, par: par, course: course)
        newHole.score = score
        newHole.notes = notes.isEmpty ? nil : notes
        newHole.weather = weather.isEmpty ? nil : weather
        newHole.mood = mood.isEmpty ? nil : mood
        newHole.strategy = strategy.isEmpty ? nil : strategy
        
        modelContext.insert(newHole)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save hole: \(error)")
        }
    }
}

#Preview {
    NewHoleView(course: GolfCourse(name: "Sample Course"))
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

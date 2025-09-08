//
//  EditHoleView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct EditHoleView: View {
    let hole: GolfHole
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var score: Int?
    @State private var notes: String
    @State private var weather: String
    @State private var mood: String
    @State private var strategy: String
    
    init(hole: GolfHole) {
        self.hole = hole
        self._score = State(initialValue: hole.score)
        self._notes = State(initialValue: hole.notes ?? "")
        self._weather = State(initialValue: hole.weather ?? "")
        self._mood = State(initialValue: hole.mood ?? "")
        self._strategy = State(initialValue: hole.strategy ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("edit.hole.information".localized)) {
                    HStack {
                        Text("edit.hole.number".localized)
                        Spacer()
                        Text("\(hole.holeNumber)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("edit.hole.par".localized)
                        Spacer()
                        Text("\(hole.par)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("edit.hole.score".localized)
                        Spacer()
                        TextField("edit.hole.score.placeholder".localized, value: $score, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("edit.hole.additional.information".localized)) {
                    TextField("edit.hole.weather".localized, text: $weather)
                    TextField("edit.hole.mood".localized, text: $mood)
                    TextField("edit.hole.strategy".localized, text: $strategy)
                    
                    TextField("edit.hole.notes".localized, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("edit.hole.videos".localized)) {
                    if hole.videos.isEmpty {
                        Text("edit.hole.no.videos.recorded".localized)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(hole.videos) { video in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(video.clubType.displayName)
                                    .font(.headline)
                                
                                Text(video.shotType.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\("edit.hole.duration".localized): \(formatDuration(video.duration))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("edit.hole.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        saveChanges()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        hole.score = score
        hole.notes = notes.isEmpty ? nil : notes
        hole.weather = weather.isEmpty ? nil : weather
        hole.mood = mood.isEmpty ? nil : mood
        hole.strategy = strategy.isEmpty ? nil : strategy
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    EditHoleView(hole: GolfHole(holeNumber: 1, holeSide: .front, par: 4))
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

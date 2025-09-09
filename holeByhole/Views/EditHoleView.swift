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
    
    @State private var myStrokes: Int?
    @State private var notes: String
    @State private var weather: String
    @State private var mood: String
    @State private var strategy: String
    
    init(hole: GolfHole) {
        self.hole = hole
        self._myStrokes = State(initialValue: hole.myStrokes)
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
                        Text("edit.hole.my.strokes".localized)
                        Spacer()
                        TextField("edit.hole.my.strokes.placeholder".localized, value: $myStrokes, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("edit.hole.score".localized)
                        Spacer()
                        Text(scoreDisplay)
                            .foregroundColor(scoreColor)
                            .fontWeight(.medium)
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
    
    // 计算属性：获取成绩显示
    private var scoreDisplay: String {
        guard let myStrokes = myStrokes else { return "—" }
        let calculatedScore = myStrokes - hole.par
        if calculatedScore == 0 {
            return "score.par".localized
        } else if calculatedScore == -1 {
            return "score.birdie".localized
        } else if calculatedScore == -2 {
            return "score.eagle".localized
        } else if calculatedScore == 1 {
            return "score.bogey".localized
        } else if calculatedScore == 2 {
            return "score.double.bogey".localized
        } else if calculatedScore > 2 {
            return "+\(calculatedScore)"
        } else {
            return "\(calculatedScore)"
        }
    }
    
    // 计算属性：获取成绩颜色
    private var scoreColor: Color {
        guard let myStrokes = myStrokes else { return .secondary }
        let calculatedScore = myStrokes - hole.par
        if calculatedScore <= -1 {
            return .green  // Birdie, Eagle等好成绩
        } else if calculatedScore == 0 {
            return .blue   // Par
        } else {
            return .red    // Bogey等坏成绩
        }
    }
    
    private func saveChanges() {
        // 确保球洞对象在数据库中
        if modelContext.model(for: hole.persistentModelID) == nil {
            modelContext.insert(hole)
        }
        
        hole.updateMyStrokes(myStrokes)
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

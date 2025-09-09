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
    let round: GolfRound?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    init(course: GolfCourse, round: GolfRound? = nil) {
        self.course = course
        self.round = round
    }
    
    @State private var holeNumber = 1
    @State private var holeSide: HoleSide = .front
    @State private var par = 4
    @State private var myStrokes: Int?
    @State private var notes = ""
    @State private var weather = ""
    @State private var mood = ""
    @State private var strategy = ""
    @State private var showingVideoRecording = false
    @State private var selectedClub: ClubType = .driver
    @State private var selectedShotType: ShotType = .tee
    
    // 计算属性：根据选择的球洞号和球洞侧获取标准杆数
    private var currentPar: Int {
        return course.getPar(for: holeNumber, holeSide: holeSide)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("hole.information".localized)) {
                    Picker("hole.side".localized, selection: $holeSide) {
                        ForEach(HoleSide.allCases, id: \.self) { side in
                            Text(side.displayName).tag(side)
                        }
                    }
                    .onChange(of: holeSide) { _, _ in
                        par = currentPar
                    }
                    
                    Picker("hole.number.label".localized, selection: $holeNumber) {
                        ForEach(1...9, id: \.self) { hole in
                            Text(String(format: holeSide == .front ? "hole.front.number".localized : "hole.back.number".localized, hole)).tag(hole)
                        }
                    }
                    .onChange(of: holeNumber) { _, _ in
                        par = currentPar
                    }
                    
                    HStack {
                        Text("courses.par".localized)
                        Spacer()
                        Text("\(currentPar)")
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
                    shotType: selectedShotType,
                    round: round,
                    existingHole: nil
                )
            }
            .onAppear {
                // 初始化标准杆数
                par = currentPar
            }
        }
    }
    
    // 计算属性：获取成绩显示
    private var scoreDisplay: String {
        guard let myStrokes = myStrokes else { return "—" }
        let calculatedScore = myStrokes - currentPar
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
        let calculatedScore = myStrokes - currentPar
        if calculatedScore <= -1 {
            return .green  // Birdie, Eagle等好成绩
        } else if calculatedScore == 0 {
            return .blue   // Par
        } else {
            return .red    // Bogey等坏成绩
        }
    }
    
    private func saveHole() {
        let newHole = GolfHole(holeNumber: holeNumber, holeSide: holeSide, par: currentPar, course: course, round: round)
        newHole.updateMyStrokes(myStrokes)
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
        .modelContainer(for: [GolfCourse.self, GolfRound.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

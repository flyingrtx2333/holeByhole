//
//  RoundDetailView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct RoundDetailView: View {
    let round: GolfRound
    @Environment(\.modelContext) private var modelContext
    @State private var showingNewHole = false
    @State private var showingEditRound = false
    
    var holesBySide: [HoleSide: [GolfHole]] {
        Dictionary(grouping: round.holes) { hole in
            hole.holeSide ?? (hole.holeNumber <= 9 ? .front : .back)
        }
    }
    
    var frontHoles: [GolfHole] {
        holesBySide[.front] ?? []
    }
    
    var backHoles: [GolfHole] {
        holesBySide[.back] ?? []
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Round Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(round.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: round.isCompleted ? "checkmark.circle.fill" : "clock.fill")
                            .foregroundColor(round.isCompleted ? .green : .orange)
                        Text(round.statusText)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        Text(round.startDate.formattedDate)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Round Stats
                if !round.holes.isEmpty {
                    HStack(spacing: 20) {
                        StatCard(
                            title: "round.total.holes".localized,
                            value: "\(round.holes.count)",
                            icon: "flag.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "round.completed.holes".localized,
                            value: "\(round.completedHolesCount)",
                            icon: "checkmark.circle.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "round.total.score".localized,
                            value: "\(totalScore)",
                            icon: "number",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Front 9 Holes
                VStack(alignment: .leading, spacing: 12) {
                    Text("hole.side.front".localized)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(1...9, id: \.self) { holeNumber in
                            HoleCard(
                                holeNumber: holeNumber,
                                holeSide: .front,
                                holes: frontHoles.filter { $0.holeNumber == holeNumber },
                                round: round
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Back 9 Holes
                VStack(alignment: .leading, spacing: 12) {
                    Text("hole.side.back".localized)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(1...9, id: \.self) { holeNumber in
                            HoleCard(
                                holeNumber: holeNumber,
                                holeSide: .back,
                                holes: backHoles.filter { $0.holeNumber == holeNumber },
                                round: round
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 100)
            }
        }
        .navigationTitle("round.details".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showingEditRound = true
                }) {
                    Image(systemName: "pencil")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingNewHole = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewHole) {
            if let course = round.course {
                NewHoleView(course: course, round: round)
            }
        }
        .sheet(isPresented: $showingEditRound) {
            EditRoundView(round: round)
        }
    }
    
    private var totalScore: Int {
        round.holes.compactMap { $0.score }.reduce(0, +)
    }
}

struct HoleCard: View {
    let holeNumber: Int
    let holeSide: HoleSide
    let holes: [GolfHole]
    let round: GolfRound
    
    var body: some View {
        NavigationLink(destination: HoleRecordDetailView(hole: holes.first ?? GolfHole(holeNumber: holeNumber, holeSide: holeSide, par: round.course?.getPar(for: holeNumber, holeSide: holeSide) ?? 4, course: round.course, round: round))) {
            VStack(spacing: 4) {
                Text(String(format: holeSide == .front ? "hole.front.number".localized : "hole.back.number".localized, holeNumber))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let hole = holes.first {
                    if let myStrokes = hole.myStrokes {
                        Text("\(myStrokes)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(score: myStrokes, par: hole.par))
                    } else {
                        Text("—")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(String(format: "par.number".localized, hole.par))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    // 如果没有球洞记录，使用球场的默认标准杆
                    let par = round.course?.getPar(for: holeNumber, holeSide: holeSide) ?? 4
                    Text("—")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "par.number".localized, par))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if holes.count > 1 {
                    Text("+\(holes.count - 1)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(holes.isEmpty ? Color(.systemGray5) : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditRoundView: View {
    let round: GolfRound
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isCompleted: Bool
    @State private var weather: String
    @State private var notes: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(round: GolfRound) {
        self.round = round
        self._isCompleted = State(initialValue: round.isCompleted)
        self._weather = State(initialValue: round.weather ?? "")
        self._notes = State(initialValue: round.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("round.status".localized) {
                    Toggle("round.completed".localized, isOn: $isCompleted)
                }
                
                Section("round.weather".localized) {
                    TextField("round.weather.placeholder".localized, text: $weather)
                }
                
                Section("round.notes".localized) {
                    TextField("round.notes.placeholder".localized, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("round.edit".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        saveRound()
                    }
                }
            }
            .alert("round.save.failed".localized, isPresented: $showingAlert) {
                Button("common.ok".localized) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveRound() {
        round.isCompleted = isCompleted
        round.weather = weather.isEmpty ? nil : weather
        round.notes = notes.isEmpty ? nil : notes
        
        if isCompleted && round.endDate == nil {
            round.endDate = Date()
        } else if !isCompleted {
            round.endDate = nil
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

#Preview {
    NavigationView {
        RoundDetailView(round: GolfRound(roundNumber: 1, course: GolfCourse(name: "Sample Course")))
    }
    .modelContainer(for: [GolfCourse.self, GolfRound.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

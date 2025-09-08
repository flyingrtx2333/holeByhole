//
//  CourseDetailView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct CourseDetailView: View {
    let course: GolfCourse
    @Environment(\.modelContext) private var modelContext
    @State private var showingNewHole = false
    
    var holesBySide: [HoleSide: [GolfHole]] {
        Dictionary(grouping: course.holes) { hole in
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
                // Course Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(course.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let location = course.location {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.secondary)
                            Text(location)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.green)
                        Text(String(format: "course.holes.recorded".localized, course.holes.count))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Quick Stats
                if !course.holes.isEmpty {
                    HStack(spacing: 20) {
                        StatCard(
                            title: "courses.best.score".localized,
                            value: "\(course.holes.compactMap { $0.score }.min() ?? 0)",
                            icon: "trophy.fill",
                            color: .yellow
                        )
                        
                        StatCard(
                            title: "courses.average".localized,
                            value: String(format: "%.1f", averageScore),
                            icon: "chart.line.uptrend.xyaxis",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "courses.par".localized,
                            value: "\(course.holes.map { $0.par }.reduce(0, +))",
                            icon: "target",
                            color: .green
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
                                course: course
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
                                course: course
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 100)
            }
        }
        .navigationTitle("course.details".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingNewHole = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewHole) {
            NewHoleView(course: course)
        }
    }
    
    private var averageScore: Double {
        let scores = course.holes.compactMap { $0.score }
        guard !scores.isEmpty else { return 0 }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HoleCard: View {
    let holeNumber: Int
    let holeSide: HoleSide
    let holes: [GolfHole]
    let course: GolfCourse
    
    
    var body: some View {
        NavigationLink(destination: HoleDetailView(holeNumber: holeNumber, course: course)) {
            VStack(spacing: 4) {
                Text(String(format: holeSide == .front ? "hole.front.number".localized : "hole.back.number".localized, holeNumber))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let hole = holes.first {
                    if let score = hole.score {
                        Text("\(score)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(score: score, par: hole.par))
                    } else {
                        Text("—")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(String(format: "par.number".localized, hole.par))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("—")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("ui.no.data".localized)
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
    
    private func scoreColor(score: Int, par: Int) -> Color {
        let difference = score - par
        switch difference {
        case ..<0: return .red // Under par
        case 0: return .green // Par
        case 1: return .orange // Bogey
        default: return .red // Double bogey or worse
        }
    }
}

#Preview {
    NavigationView {
        CourseDetailView(course: GolfCourse(name: "Sample Course", location: "Sample Location"))
    }
    .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

//
//  HoleDetailView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct HoleDetailView: View {
    let holeNumber: Int
    let course: GolfCourse
    @Environment(\.modelContext) private var modelContext
    @Query private var holes: [GolfHole]
    
    var holeData: [GolfHole] {
        holes.filter { $0.holeNumber == holeNumber && $0.course?.id == course.id }
    }
    
    var holeSide: HoleSide {
        // 从现有数据推断洞区，如果没有数据则根据洞号推断
        if let firstHole = holeData.first, let side = firstHole.holeSide {
            return side
        } else {
            return holeNumber <= 9 ? .front : .back
        }
    }
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hole Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: holeSide == .front ? "hole.front.number".localized : "hole.back.number".localized, holeNumber))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(course.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                if holeData.isEmpty {
                    EmptyHoleView(holeNumber: holeNumber, course: course)
                } else {
                    // Hole Statistics
                    HStack(spacing: 20) {
                        StatCard(
                            title: "courses.best.score".localized,
                            value: "\(holeData.compactMap { $0.score }.min() ?? 0)",
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
                            value: "\(holeData.first?.par ?? 4)",
                            icon: "target",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Hole Records
                    VStack(alignment: .leading, spacing: 12) {
                        Text("hole.records".localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(holeData.sorted { $0.createdAt > $1.createdAt }) { hole in
                                HoleRecordCard(hole: hole)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .navigationTitle(String(format: holeSide == .front ? "hole.front.number".localized : "hole.back.number".localized, holeNumber))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var averageScore: Double {
        let scores = holeData.compactMap { $0.score }
        guard !scores.isEmpty else { return 0 }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }
}

struct EmptyHoleView: View {
    let holeNumber: Int
    let course: GolfCourse
    @State private var showingNewHole = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "flag")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("hole.no.records".localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(String(format: "hole.start.recording".localized, holeNumber))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingNewHole = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("hole.record.hole".localized)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingNewHole) {
            NewHoleView(course: course)
        }
    }
}

struct HoleRecordCard: View {
    let hole: GolfHole
    
    var body: some View {
        NavigationLink(destination: HoleRecordDetailView(hole: hole)) {
            VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let score = hole.score {
                        Text("\(score)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(score: score, par: hole.par))
                    } else {
                        Text("hole.no.score".localized)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(String(format: "par.number".localized, hole.par))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(hole.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(hole.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if !hole.videos.isEmpty {
                HStack {
                    Image(systemName: "video.fill")
                        .foregroundColor(.blue)
                    Text("\(hole.videos.count) \(hole.videos.count == 1 ? "ui.video".localized : "ui.videos".localized)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if let notes = hole.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            if let weather = hole.weather, !weather.isEmpty {
                HStack {
                    Image(systemName: "cloud.fill")
                        .foregroundColor(.gray)
                    Text(weather)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
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
        HoleDetailView(holeNumber: 1, course: GolfCourse(name: "Sample Course"))
    }
    .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

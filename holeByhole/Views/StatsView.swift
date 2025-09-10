//
//  StatsView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var holes: [GolfHole]
    @Query private var courses: [GolfCourse]
    @Query private var videos: [GolfVideo]
    
    @State private var selectedTimeRange: TimeRange = .all
    @State private var selectedCourse: GolfCourse?
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var filteredHoles: [GolfHole] {
        var filtered = holes
        
        // Filter by time range
        switch selectedTimeRange {
        case .all:
            break
        case .lastWeek:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            filtered = filtered.filter { $0.createdAt >= oneWeekAgo }
        case .lastMonth:
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.createdAt >= oneMonthAgo }
        case .lastYear:
            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.createdAt >= oneYearAgo }
        }
        
        // Filter by course
        if let course = selectedCourse {
            filtered = filtered.filter { $0.course?.id == course.id }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Filters
                    VStack(spacing: 12) {
                        Picker("stats.time.range".localized, selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if !courses.isEmpty {
                            Picker("stats.course".localized, selection: $selectedCourse) {
                                Text("stats.all.courses".localized).tag(nil as GolfCourse?)
                                ForEach(courses) { course in
                                    Text(course.name).tag(course as GolfCourse?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    if filteredHoles.isEmpty {
                        EmptyStatsView()
                    } else {
                        // Overview Stats
                        OverviewStatsView(holes: filteredHoles)
                        
                        // Score Distribution Chart
                        ScoreDistributionView(holes: filteredHoles)
                        
                        // Performance by Hole
                        PerformanceByHoleView(holes: filteredHoles)
                        
                        // Club Usage Stats
                        ClubUsageView(videos: videos)
                        
                        // Recent Performance
                        RecentPerformanceView(holes: filteredHoles)
                    }
                }
            }
            .navigationTitle("stats.title".localized)
            .onChange(of: localizationManager.currentLanguage) { _, _ in
                // Force view refresh when language changes
            }
        }
    }
}

enum TimeRange: CaseIterable {
    case all, lastWeek, lastMonth, lastYear
    
    var displayName: String {
        switch self {
        case .all: return "stats.time.range.all".localized
        case .lastWeek: return "stats.time.range.last.week".localized
        case .lastMonth: return "stats.time.range.last.month".localized
        case .lastYear: return "stats.time.range.last.year".localized
        }
    }
}

struct OverviewStatsView: View {
    let holes: [GolfHole]
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var scoredHoles: [GolfHole] {
        holes.filter { $0.myStrokes != nil }
    }
    
    // 计算已打轮次数量
    var roundsPlayed: Int {
        let uniqueRounds = Set(holes.compactMap { $0.round?.id })
        return uniqueRounds.count
    }
    
    var averageScore: Double {
        guard !scoredHoles.isEmpty else { return 0 }
        let totalScore = scoredHoles.compactMap { hole in
            guard let myStrokes = hole.myStrokes else { return nil }
            return myStrokes - hole.par
        }.reduce(0, +)
        return Double(totalScore) / Double(scoredHoles.count)
    }
    
    var bestScore: Int {
        scoredHoles.compactMap { hole in
            guard let myStrokes = hole.myStrokes else { return nil }
            return myStrokes - hole.par
        }.min() ?? 0
    }
    
    var worstScore: Int {
        scoredHoles.compactMap { hole in
            guard let myStrokes = hole.myStrokes else { return nil }
            return myStrokes - hole.par
        }.max() ?? 0
    }
    
    var totalPar: Int {
        holes.map { $0.par }.reduce(0, +)
    }
    
    var totalScore: Int {
        scoredHoles.compactMap { hole in
            guard let myStrokes = hole.myStrokes else { return nil }
            return myStrokes - hole.par
        }.reduce(0, +)
    }
    
    var bestScoreDisplay: String {
        if bestScore == 0 {
            return "score.par".localized
        } else if bestScore == -1 {
            return "score.birdie".localized
        } else if bestScore == -2 {
            return "score.eagle".localized
        } else if bestScore == 1 {
            return "score.bogey".localized
        } else if bestScore == 2 {
            return "score.double.bogey".localized
        } else if bestScore > 2 {
            return "+\(bestScore)"
        } else {
            return "\(bestScore)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats.overview.title".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    title: "stats.rounds.played".localized,
                    value: "\(roundsPlayed)",
                    icon: "flag.fill",
                    color: .green
                )
                
                StatCard(
                    title: "stats.average.score".localized,
                    value: String(format: "%.1f", averageScore),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
                
                StatCard(
                    title: "stats.best.score".localized,
                    value: bestScoreDisplay,
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "stats.total.par".localized,
                    value: "\(totalPar)",
                    icon: "target",
                    color: .orange
                )
            }
            .padding(.horizontal)
            .onChange(of: localizationManager.currentLanguage) { _, _ in
                // Force view refresh when language changes
            }
        }
    }
}

struct ScoreDistributionView: View {
    let holes: [GolfHole]
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var scoreDistribution: [String: Int] {
        let scoredHoles = holes.filter { $0.myStrokes != nil }
        var distribution: [String: Int] = [:]
        
        for hole in scoredHoles {
            let score = hole.myStrokes! - hole.par
            let key = scoreDisplay(score: score)
            distribution[key, default: 0] += 1
        }
        
        return distribution
    }
    
    // 计算属性：获取成绩显示
    private func scoreDisplay(score: Int) -> String {
        if score == 0 {
            return "score.par".localized
        } else if score == -1 {
            return "score.birdie".localized
        } else if score == -2 {
            return "score.eagle".localized
        } else if score == 1 {
            return "score.bogey".localized
        } else if score == 2 {
            return "score.double.bogey".localized
        } else if score > 2 {
            return "+\(score)"
        } else {
            return "\(score)"
        }
    }
    
    // 成绩排序函数
    private func scoreOrder(_ scoreString: String) -> Int {
        if scoreString == "score.eagle".localized { return -2 }
        else if scoreString == "score.birdie".localized { return -1 }
        else if scoreString == "score.par".localized { return 0 }
        else if scoreString == "score.bogey".localized { return 1 }
        else if scoreString == "score.double.bogey".localized { return 2 }
        else if scoreString.hasPrefix("+") {
            return Int(scoreString.dropFirst()) ?? 3
        } else if let score = Int(scoreString) {
            return score
        }
        return 999 // 未知成绩排在最后
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats.score.distribution".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if !scoreDistribution.isEmpty {
                Chart {
                    ForEach(scoreDistribution.sorted(by: { scoreOrder($0.key) < scoreOrder($1.key) }), id: \.key) { score, count in
                        BarMark(
                            x: .value("Score", score),
                            y: .value("Count", count)
                        )
                        .foregroundStyle(.green)
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
            } else {
                Text("stats.no.score.data".localized)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .onChange(of: localizationManager.currentLanguage) { _, _ in
            // Force view refresh when language changes
        }
    }
}

struct PerformanceByHoleView: View {
    let holes: [GolfHole]
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var holesBySide: [HoleSide: [GolfHole]] {
        Dictionary(grouping: holes) { hole in
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
        VStack(alignment: .leading, spacing: 12) {
            Text("stats.performance.by.hole".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            // Front 9 Holes
            VStack(alignment: .leading, spacing: 8) {
                Text("hole.side.front".localized)
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(1...9, id: \.self) { holeNumber in
                        let holeData = frontHoles.filter { $0.holeNumber == holeNumber }
                        let scoredHoles = holeData.filter { $0.myStrokes != nil }
                        let averageScore = scoredHoles.isEmpty ? nil : 
                            Double(scoredHoles.compactMap { hole in
                                guard let myStrokes = hole.myStrokes else { return nil }
                                return myStrokes - hole.par
                            }.reduce(0, +)) / Double(scoredHoles.count)
                        
                        VStack(spacing: 4) {
                            Text(String(format: "hole.front.number".localized, holeNumber))
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            if let averageScore = averageScore {
                                Text(String(format: "%.1f", averageScore))
                                    .font(.caption2)
                                    .foregroundColor(scoreColor(averageScore: averageScore))
                            } else {
                                Text("—")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            
            // Back 9 Holes
            VStack(alignment: .leading, spacing: 8) {
                Text("hole.side.back".localized)
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(1...9, id: \.self) { holeNumber in
                        let holeData = backHoles.filter { $0.holeNumber == holeNumber }
                        let scoredHoles = holeData.filter { $0.myStrokes != nil }
                        let averageScore = scoredHoles.isEmpty ? nil : 
                            Double(scoredHoles.compactMap { hole in
                                guard let myStrokes = hole.myStrokes else { return nil }
                                return myStrokes - hole.par
                            }.reduce(0, +)) / Double(scoredHoles.count)
                        
                        VStack(spacing: 4) {
                            Text(String(format: "hole.back.number".localized, holeNumber))
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            if let averageScore = averageScore {
                                Text(String(format: "%.1f", averageScore))
                                    .font(.caption2)
                                    .foregroundColor(scoreColor(averageScore: averageScore))
                            } else {
                                Text("—")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onChange(of: localizationManager.currentLanguage) { _, _ in
            // Force view refresh when language changes
        }
    }
    
    private func scoreColor(averageScore: Double) -> Color {
        if averageScore <= -0.5 { return .green }  // 小鸟球或更好
        else if averageScore <= 0.5 { return .blue }  // 标准杆附近
        else if averageScore <= 1.5 { return .orange }  // 柏忌
        else { return .red }  // 双柏忌或更差
    }
}

struct ClubUsageView: View {
    let videos: [GolfVideo]
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var clubUsage: [ClubType: Int] {
        var usage: [ClubType: Int] = [:]
        for video in videos {
            usage[video.clubType, default: 0] += 1
        }
        return usage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats.club.usage".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if !clubUsage.isEmpty {
                LazyVStack(spacing: 8) {
                    ForEach(ClubType.allCases, id: \.self) { club in
                        let count = clubUsage[club] ?? 0
                        HStack {
                            Text(club.displayName)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
            } else {
                Text("stats.no.club.data".localized)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .onChange(of: localizationManager.currentLanguage) { _, _ in
            // Force view refresh when language changes
        }
    }
}

struct RecentPerformanceView: View {
    let holes: [GolfHole]
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var recentHoles: [GolfHole] {
        holes.sorted { $0.createdAt > $1.createdAt }.prefix(10).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats.recent.performance".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(recentHoles) { hole in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: (hole.holeSide ?? (hole.holeNumber <= 9 ? .front : .back)) == .front ? "hole.front.number".localized : "hole.back.number".localized, hole.holeNumber))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if let course = hole.course {
                                Text(course.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            if let myStrokes = hole.myStrokes {
                                Text("\(myStrokes)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(scoreColor(score: myStrokes, par: hole.par))
                            } else {
                                Text("—")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(String(format: "stats.par.format".localized, hole.par))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onChange(of: localizationManager.currentLanguage) { _, _ in
            // Force view refresh when language changes
        }
    }
    
}

struct EmptyStatsView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("stats.no.statistics.title".localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("stats.no.statistics.message".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: localizationManager.currentLanguage) { _, _ in
            // Force view refresh when language changes
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

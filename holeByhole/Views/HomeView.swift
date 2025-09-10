//
//  HomeView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GolfHole.createdAt, order: .reverse) private var recentHoles: [GolfHole]
    @Query private var courses: [GolfCourse]
    @State private var showingNewRound = false
    @State private var showingRecordingSetup = false
    @State private var showingCourseSelection = false
    @State private var showingRoundSelection = false
    @State private var currentCourse: GolfCourse?
    @State private var currentRound: GolfRound?
    @StateObject private var localizationManager = LocalizationManager.shared
    
    private let userDefaultsManager = UserDefaultsManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Welcome Section - Only show when no course/round selected
                    if currentCourse == nil || currentRound == nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("home.welcome".localized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("app.subtitle".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Current Status
                    VStack(alignment: .leading, spacing: 12) {
                        Text("home.current.status".localized)
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            Button(action: {
                                showingCourseSelection = true
                            }) {
                                HStack {
                                    // 球场图片
                                    if let course = currentCourse,
                                       let photoPath = course.photoPath,
                                       let image = AppFileManager.shared.loadCoursePhoto(from: photoPath) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 40, height: 40)
                                            .clipped()
                                            .cornerRadius(8)
                                    } else {
                                        Image(systemName: "map.fill")
                                            .font(.title2)
                                            .foregroundColor(.secondary)
                                            .frame(width: 40, height: 40)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("home.current.course".localized)
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Text(currentCourse?.name ?? "home.no.course.selected".localized)
                                            .fontWeight(.semibold)
                                            .foregroundColor(currentCourse == nil ? .secondary : .primary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                if currentCourse != nil {
                                    showingRoundSelection = true
                                }
                            }) {
                                HStack {
                                    Text("home.current.round".localized)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(currentRound?.displayName ?? "home.no.round.selected".localized)
                                        .fontWeight(.semibold)
                                        .foregroundColor(currentRound == nil ? .secondary : .primary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(currentCourse == nil)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(spacing: 16) {
                        Button(action: {
                            showingNewRound = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("home.start.new.round".localized)
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingRecordingSetup = true
                        }) {
                            HStack {
                                Image(systemName: "video.fill")
                                    .font(.title2)
                                Text("home.start.recording".localized)
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(currentRound == nil ? Color.gray.opacity(0.1) : Color.red.opacity(0.1))
                            .foregroundColor(currentRound == nil ? .gray : .red)
                            .cornerRadius(12)
                        }
                        .disabled(currentRound == nil)
                    }
                    .padding(.horizontal)
                    
                    // Recent Activity
                    if !recentHoles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("home.recent.activity".localized)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(recentHoles.prefix(5)) { hole in
                                    RecentHoleCard(hole: hole)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("home.title".localized)
            .onAppear {
                loadCurrentState()
            }
            .onChange(of: localizationManager.currentLanguage) { _, _ in
                // Force view refresh when language changes
            }
            .sheet(isPresented: $showingNewRound) {
                NewRoundView { course, round in
                    setCurrentCourse(course)
                    setCurrentRound(round)
                }
            }
            .sheet(isPresented: $showingRecordingSetup) {
                if let course = currentCourse, let round = currentRound {
                    RecordingSetupView(course: course, round: round)
                }
            }
            .sheet(isPresented: $showingCourseSelection) {
                CourseSelectionView(selectedCourse: $currentCourse)
                    .onDisappear {
                        // 当选择新球场时，自动切换到最新轮次
                        if let course = currentCourse {
                            setCurrentCourse(course)
                            // 自动选择最新轮次
                            let latestRound = course.rounds.sorted { $0.startDate > $1.startDate }.first
                            setCurrentRound(latestRound)
                        }
                    }
            }
            .sheet(isPresented: $showingRoundSelection) {
                if let course = currentCourse {
                    RoundSelectionView(course: course, selectedRound: $currentRound)
                        .onDisappear {
                            if currentRound != nil {
                                setCurrentRound(currentRound)
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadCurrentState() {
        currentCourse = userDefaultsManager.findCurrentCourse(in: modelContext)
        currentRound = userDefaultsManager.findCurrentRound(in: modelContext)
    }
    
    private func setCurrentCourse(_ course: GolfCourse?) {
        currentCourse = course
        userDefaultsManager.setCurrentCourse(course)
    }
    
    private func setCurrentRound(_ round: GolfRound?) {
        currentRound = round
        userDefaultsManager.setCurrentRound(round)
    }
}

struct RecentHoleCard: View {
    let hole: GolfHole
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationLink(destination: HoleRecordDetailView(hole: hole)) {
            HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: (hole.holeSide ?? (hole.holeNumber <= 9 ? .front : .back)) == .front ? "hole.front.number".localized : "hole.back.number".localized, hole.holeNumber))
                    .font(.headline)
                
                if let course = hole.course {
                    Text(course.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let round = hole.round {
                    Text(round.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(hole.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let myStrokes = hole.myStrokes {
                    // 显示我的杆数
                    Text("\(myStrokes)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // 显示成绩（我的杆数 - 标准杆数）
                    let score = myStrokes - hole.par
                    Text(scoreDisplay(score: score))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(scoreColor(score: myStrokes, par: hole.par))
                } else {
                    Text("hole.no.score".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(String(format: "par.number".localized, hole.par))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: localizationManager.currentLanguage) { _, _ in
            // Force view refresh when language changes
        }
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
}

#Preview {
    HomeView()
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

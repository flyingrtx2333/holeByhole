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
                VStack(spacing: 0) {
                    // 球场大图背景区域
                    ZStack(alignment: .bottomLeading) {
                        // 球场背景图片
                        if let course = currentCourse,
                           let photoPath = course.photoPath,
                           let image = AppFileManager.shared.loadCoursePhoto(from: photoPath) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 300)
                                .clipped()
                        } else {
                            // 默认背景
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green.opacity(0.8), Color.blue.opacity(0.6)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 300)
                        }
                        
                        // 渐变遮罩，确保文字可读性
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 300)
                        
                        // 左下角：球场和轮次选择器
                        VStack(alignment: .leading, spacing: 12) {
                            // 球场选择器
                            Button(action: {
                                showingCourseSelection = true
                            }) {
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("home.current.course".localized)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(currentCourse?.name ?? "home.no.course.selected".localized)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 轮次选择器
                            Button(action: {
                                if currentCourse != nil {
                                    showingRoundSelection = true
                                }
                            }) {
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("home.current.round".localized)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(currentRound?.displayName ?? "home.no.round.selected".localized)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(currentCourse == nil)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        
                        // 右下角：开始录制按钮
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    showingRecordingSetup = true
                                }) {
                                    Image(systemName: "video.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 60, height: 60)
                                        .background(
                                            Circle()
                                                .fill(currentRound == nil ? Color.gray : Color.red)
                                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(currentRound == nil)
                                .padding(.trailing, 20)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                    .frame(height: 300)
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("home.recent.activity".localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        if !recentHoles.isEmpty {
                            LazyVStack(spacing: 8) {
                                ForEach(recentHoles.prefix(5)) { hole in
                                    RecentHoleCard(hole: hole)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            // 暂无活动状态
                            VStack(spacing: 12) {
                                Image(systemName: "golf.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("home.no.activity".localized)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("home.add.first.course".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 40)
                            .frame(maxWidth: .infinity)
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
                
                Text(hole.createdAt.formattedDateTime)
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

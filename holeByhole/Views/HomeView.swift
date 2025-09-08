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
    @State private var showingNewRound = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("home.welcome".localized)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("app.subtitle".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                        
                        NavigationLink(destination: CourseListView()) {
                            HStack {
                                Image(systemName: "map.fill")
                                    .font(.title2)
                                Text("home.browse.courses".localized)
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
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
            .sheet(isPresented: $showingNewRound) {
                NewRoundView()
            }
        }
    }
}

struct RecentHoleCard: View {
    let hole: GolfHole
    
    var body: some View {
        NavigationLink(destination: HoleDetailView(holeNumber: hole.holeNumber, course: hole.course ?? GolfCourse(name: "Unknown Course"))) {
            HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: (hole.holeSide ?? (hole.holeNumber <= 9 ? .front : .back)) == .front ? "hole.front.number".localized : "hole.back.number".localized, hole.holeNumber))
                    .font(.headline)
                
                if let course = hole.course {
                    Text(course.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(hole.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let score = hole.score {
                    Text("\(score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(score: score, par: hole.par))
                } else {
                    Text("hole.no.score".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                    Text(String(format: "par.number".localized, hole.par))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            }
            .padding()
            .background(Color(.systemGray6))
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
    HomeView()
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

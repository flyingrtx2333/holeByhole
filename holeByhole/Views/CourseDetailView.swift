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
    @State private var showingNewRound = false
    @State private var showingEditCourse = false
    
    var sortedRounds: [GolfRound] {
        course.rounds.sorted { $0.roundNumber > $1.roundNumber }
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
                        Image(systemName: "flag.2.crossed.fill")
                            .foregroundColor(.green)
                        Text(String(format: "course.rounds.count".localized, course.roundsCount))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Quick Stats
                if !course.rounds.isEmpty {
                    HStack(spacing: 20) {
                        StatCard(
                            title: "courses.total.rounds".localized,
                            value: "\(course.roundsCount)",
                            icon: "flag.2.crossed.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "courses.completed.rounds".localized,
                            value: "\(course.rounds.filter { $0.isCompleted }.count)",
                            icon: "checkmark.circle.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "courses.total.holes".localized,
                            value: "\(course.totalHolesCount)",
                            icon: "flag.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Rounds List
                VStack(alignment: .leading, spacing: 12) {
                    Text("course.rounds".localized)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    if sortedRounds.isEmpty {
                        EmptyRoundsView()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(sortedRounds) { round in
                                NavigationLink(destination: RoundDetailView(round: round)) {
                                    RoundCard(round: round)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .navigationTitle("course.details".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showingEditCourse = true
                }) {
                    Image(systemName: "pencil")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingNewRound = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewRound) {
            NewRoundView()
        }
        .sheet(isPresented: $showingEditCourse) {
            EditCourseView(course: course)
        }
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

struct RoundCard: View {
    let round: GolfRound
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(round.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Image(systemName: round.isCompleted ? "checkmark.circle.fill" : "clock.fill")
                        .foregroundColor(round.isCompleted ? .green : .orange)
                        .font(.caption)
                    Text(round.statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text(String(format: "round.holes.completed".localized, round.completedHolesCount, round.holes.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let notes = round.notes, !notes.isEmpty {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(round.completedHolesCount)/\(round.holes.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("ui.holes".localized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmptyRoundsView: View {
    let title: String
    let message: String
    
    init(title: String = "course.no.rounds".localized, message: String = "course.start.first.round".localized) {
        self.title = title
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.2.crossed")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    NavigationView {
        CourseDetailView(course: GolfCourse(name: "Sample Course", location: "Sample Location"))
    }
    .modelContainer(for: [GolfCourse.self, GolfRound.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

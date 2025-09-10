//
//  CourseListView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct CourseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var courses: [GolfCourse]
    @State private var showingAddCourse = false
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var coursesToDelete: IndexSet = []
    
    var filteredCourses: [GolfCourse] {
        if searchText.isEmpty {
            return courses.sorted { $0.name < $1.name }
        } else {
            return courses.filter { course in
                course.name.localizedCaseInsensitiveContains(searchText) ||
                (course.location?.displayAddress.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (course.location?.city?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (course.location?.country?.localizedCaseInsensitiveContains(searchText) ?? false)
            }.sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if courses.isEmpty {
                    EmptyStateView(showingAddCourse: $showingAddCourse)
                } else {
                    List {
                        ForEach(filteredCourses) { course in
                            NavigationLink(destination: CourseDetailView(course: course)) {
                                CourseListRowView(course: course)
                            }
                        }
                        .onDelete(perform: showDeleteConfirmation)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("courses.title".localized)
            .searchable(text: $searchText, prompt: "courses.search.placeholder".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddCourse = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCourse) {
                AddCourseView()
            }
            .alert("common.delete".localized, isPresented: $showingDeleteAlert) {
                Button("common.cancel".localized, role: .cancel) { }
                Button("common.delete".localized, role: .destructive) {
                    deleteCourses(offsets: coursesToDelete)
                }
            } message: {
                Text("course.delete.confirmation".localized)
            }
        }
    }
    
    private func showDeleteConfirmation(offsets: IndexSet) {
        coursesToDelete = offsets
        showingDeleteAlert = true
    }
    
    private func deleteCourses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let course = filteredCourses[index]
                
                // Delete all rounds and their associated data
                for round in course.rounds {
                    // Delete all holes in this round
                    for hole in round.holes {
                        // Delete all videos for this hole
                        for video in hole.videos {
                            // Delete video file
                            AppFileManager.shared.deleteVideoFile(at: URL(fileURLWithPath: video.filePath))
                            
                            // Delete thumbnail file if exists
                            if let thumbnailPath = video.thumbnailPath {
                                AppFileManager.shared.deleteThumbnailFile(at: thumbnailPath)
                            }
                            
                            modelContext.delete(video)
                        }
                        
                        // Delete the hole
                        modelContext.delete(hole)
                    }
                    
                    // Delete the round
                    modelContext.delete(round)
                }
                
                // Delete the course
                modelContext.delete(course)
            }
            
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete courses: \(error)")
            }
        }
    }
}

struct CourseListRowView: View {
    let course: GolfCourse
    
    var body: some View {
        HStack {
            // 球场缩略图
            if let photoPath = course.photoPath,
               let image = AppFileManager.shared.loadCoursePhoto(from: photoPath) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Image(systemName: "map")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 60, height: 60)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                
                if let location = course.location {
                    Text(location.displayAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Image(systemName: "flag.2.crossed.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(String(format: "course.rounds.count".localized, course.roundsCount))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(course.roundsCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("ui.rounds".localized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyStateView: View {
    @Binding var showingAddCourse: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("courses.no.courses".localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("home.add.first.course".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingAddCourse = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("courses.add.course".localized)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CourseListView()
        .modelContainer(for: [GolfCourse.self, GolfRound.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

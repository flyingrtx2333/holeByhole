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
    
    var filteredCourses: [GolfCourse] {
        if searchText.isEmpty {
            return courses.sorted { $0.name < $1.name }
        } else {
            return courses.filter { course in
                course.name.localizedCaseInsensitiveContains(searchText) ||
                (course.location?.localizedCaseInsensitiveContains(searchText) ?? false)
            }.sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if courses.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(filteredCourses) { course in
                            NavigationLink(destination: CourseDetailView(course: course)) {
                                CourseListRowView(course: course)
                            }
                        }
                        .onDelete(perform: deleteCourses)
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
        }
    }
    
    private func deleteCourses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let course = filteredCourses[index]
                modelContext.delete(course)
            }
        }
    }
}

struct CourseListRowView: View {
    let course: GolfCourse
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                
                if let location = course.location {
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(String(format: "course.holes.recorded".localized, course.holes.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(course.holes.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("ui.recorded".localized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyStateView: View {
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
                // This will be handled by the parent view
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
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

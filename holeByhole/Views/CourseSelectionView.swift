//
//  CourseSelectionView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct CourseSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var courses: [GolfCourse]
    
    @Binding var selectedCourse: GolfCourse?
    @State private var showingAddCourse = false
    @State private var searchText = ""
    
    var filteredCourses: [GolfCourse] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter { course in
                course.name.localizedCaseInsensitiveContains(searchText) ||
                (course.location?.displayAddress.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (course.location?.city?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (course.location?.country?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("course.selection.search.placeholder".localized, text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Course List
                List {
                    ForEach(filteredCourses) { course in
                        CourseRowView(
                            course: course,
                            isSelected: selectedCourse?.id == course.id
                        ) {
                            selectedCourse = course
                            dismiss()
                        }
                    }
                    .onDelete(perform: deleteCourses)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("course.selection.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
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

struct CourseRowView: View {
    let course: GolfCourse
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let location = course.location {
                        Text(location.displayAddress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(String(format: "course.selection.rounds.count".localized, course.roundsCount))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CourseSelectionView(selectedCourse: .constant(nil))
        .modelContainer(for: [GolfCourse.self, GolfRound.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

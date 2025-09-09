//
//  EditCourseView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct EditCourseView: View {
    let course: GolfCourse
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var courseName: String
    @State private var location: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(course: GolfCourse) {
        self.course = course
        self._courseName = State(initialValue: course.name)
        self._location = State(initialValue: course.location ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("course.information".localized)) {
                    TextField("course.name".localized, text: $courseName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("course.location".localized, text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(footer: Text("course.edit.note".localized)) {
                    EmptyView()
                }
            }
            .navigationTitle("course.edit.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        saveCourse()
                    }
                    .disabled(courseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("common.error".localized, isPresented: $showingAlert) {
                Button("common.ok".localized) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveCourse() {
        let trimmedName = courseName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "course.name.required".localized
            showingAlert = true
            return
        }
        
        // Check if course name already exists (excluding current course)
        let existingCourses = try? modelContext.fetch(FetchDescriptor<GolfCourse>())
        if let existing = existingCourses, 
           existing.contains(where: { $0.name.lowercased() == trimmedName.lowercased() && $0.id != course.id }) {
            alertMessage = "course.exists".localized
            showingAlert = true
            return
        }
        
        // Update course properties
        course.name = trimmedName
        course.location = trimmedLocation.isEmpty ? nil : trimmedLocation
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = String(format: "course.save.failed".localized, error.localizedDescription)
            showingAlert = true
        }
    }
}

#Preview {
    EditCourseView(course: GolfCourse(name: "Sample Course", location: "Sample Location"))
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

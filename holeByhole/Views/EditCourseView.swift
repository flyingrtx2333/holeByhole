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
    @State private var frontNinePar: [Int]
    @State private var backNinePar: [Int]
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(course: GolfCourse) {
        self.course = course
        self._courseName = State(initialValue: course.name)
        self._location = State(initialValue: course.location ?? "")
        self._frontNinePar = State(initialValue: course.frontNinePar)
        self._backNinePar = State(initialValue: course.backNinePar)
        // 加载现有照片
        if let photoPath = course.photoPath {
            self._selectedImage = State(initialValue: AppFileManager.shared.loadCoursePhoto(from: photoPath))
        }
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
                
                Section(header: Text("course.photo".localized)) {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(8)
                            } else {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, height: 60)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(selectedImage == nil ? "course.add.photo".localized : "course.change.photo".localized)
                                    .foregroundColor(.primary)
                                Text("course.photo.optional".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if selectedImage != nil {
                        Button(action: {
                            selectedImage = nil
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("course.remove.photo".localized)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
                
                Section(header: Text("course.front.nine.par".localized)) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(0..<9, id: \.self) { index in
                            VStack {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Picker("", selection: $frontNinePar[index]) {
                                    ForEach(3...6, id: \.self) { par in
                                        Text("\(par)").tag(par)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 80)
                            }
                        }
                    }
                }
                
                Section(header: Text("course.back.nine.par".localized)) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(0..<9, id: \.self) { index in
                            VStack {
                                Text("\(index + 10)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Picker("", selection: $backNinePar[index]) {
                                    ForEach(3...6, id: \.self) { par in
                                        Text("\(par)").tag(par)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 80)
                            }
                        }
                    }
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
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
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
        course.frontNinePar = frontNinePar
        course.backNinePar = backNinePar
        
        // 更新所有相关球洞的标准杆数
        updateHolesPar()
        
        // 更新照片
        if let selectedImage = selectedImage {
            let photoPath = AppFileManager.shared.saveCoursePhoto(selectedImage, for: course.id)
            course.photoPath = photoPath
        } else if course.photoPath != nil {
            // 如果删除了照片，删除文件并清除路径
            AppFileManager.shared.deleteCoursePhoto(at: course.photoPath!)
            course.photoPath = nil
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = String(format: "course.save.failed".localized, error.localizedDescription)
            showingAlert = true
        }
    }
    
    private func updateHolesPar() {
        // 获取该球场的所有轮次和球洞
        for round in course.rounds {
            for hole in round.holes {
                let holeSide = hole.holeSide ?? (hole.holeNumber <= 9 ? .front : .back)
                let newPar: Int
                
                if holeSide == .front && hole.holeNumber >= 1 && hole.holeNumber <= 9 {
                    newPar = frontNinePar[hole.holeNumber - 1]
                } else if holeSide == .back && hole.holeNumber >= 1 && hole.holeNumber <= 9 {
                    newPar = backNinePar[hole.holeNumber - 1]
                } else {
                    continue // 跳过无效的球洞
                }
                
                // 更新球洞的标准杆数
                hole.updatePar(newPar)
            }
        }
        
        // 保存更改
        do {
            try modelContext.save()
        } catch {
            print("Failed to save hole par updates: \(error)")
        }
    }
}

#Preview {
    EditCourseView(course: GolfCourse(name: "Sample Course", location: "Sample Location"))
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

//
//  AddCourseView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct AddCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var courseName = ""
    @State private var selectedLocation: LocationCoordinate?
    @State private var frontNinePar: [Int] = Array(repeating: 4, count: 9)
    @State private var backNinePar: [Int] = Array(repeating: 4, count: 9)
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingLocationPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("course.information".localized)) {
                    TextField("course.name".localized, text: $courseName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        Button(action: {
                            showingLocationPicker = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("course.location".localized)
                                        .foregroundColor(.primary)
                                    
                                    if let location = selectedLocation {
                                        Text(location.displayAddress)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    } else {
                                        Text("location.tap.to.select".localized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if selectedLocation != nil {
                            Button(action: {
                                selectedLocation = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
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
                
                Section(footer: Text("course.add.holes.note".localized)) {
                    EmptyView()
                }
            }
            .navigationTitle("course.add.title".localized)
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
            .sheet(isPresented: $showingLocationPicker) {
                MapLocationPickerView(selectedLocation: $selectedLocation)
            }
        }
    }
    
    private func saveCourse() {
        let trimmedName = courseName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "course.name.required".localized
            showingAlert = true
            return
        }
        
        // Check if course already exists
        let existingCourses = try? modelContext.fetch(FetchDescriptor<GolfCourse>())
        if let existing = existingCourses, existing.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            alertMessage = "course.exists".localized
            showingAlert = true
            return
        }
        
        let newCourse = GolfCourse(
            name: trimmedName,
            location: selectedLocation
        )
        
        // 设置标准杆
        newCourse.frontNinePar = frontNinePar
        newCourse.backNinePar = backNinePar
        
        // 保存照片
        if let selectedImage = selectedImage {
            let photoPath = AppFileManager.shared.saveCoursePhoto(selectedImage, for: newCourse.id)
            newCourse.photoPath = photoPath
        }
        
        modelContext.insert(newCourse)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = String(format: "course.save.failed".localized, error.localizedDescription)
            showingAlert = true
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddCourseView()
        .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

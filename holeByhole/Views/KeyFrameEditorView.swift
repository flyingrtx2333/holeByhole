//
//  KeyFrameEditorView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct KeyFrameEditorView: View {
    let video: GolfVideo
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var newKeyFrameTime: Double = 0
    @State private var newKeyFrameDescription = ""
    @State private var showingAddKeyFrame = false
    
    var sortedKeyFrames: [VideoKeyFrame] {
        video.keyFrames.sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("video.key.frames".localized)) {
                    ForEach(sortedKeyFrames) { keyFrame in
                        KeyFrameRowView(keyFrame: keyFrame)
                    }
                    .onDelete(perform: deleteKeyFrames)
                }
                
                if sortedKeyFrames.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("video.no.key.frames".localized)
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("video.key.frame.description".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("video.key.frames".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddKeyFrame = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddKeyFrame) {
                AddKeyFrameView(video: video)
            }
        }
    }
    
    
    private func deleteKeyFrames(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let keyFrame = sortedKeyFrames[index]
                modelContext.delete(keyFrame)
            }
        }
    }
}

struct KeyFrameRowView: View {
    let keyFrame: VideoKeyFrame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatTime(keyFrame.timestamp))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(keyFrame.timestamp, specifier: "%.1f")s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(keyFrame.frameDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct AddKeyFrameView: View {
    let video: GolfVideo
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var timestamp: Double = 0
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("video.key.frame.edit".localized)) {
                    HStack {
                        Text("video.key.frame.timestamp".localized)
                        Spacer()
                        TextField("video.key.frame.time.placeholder".localized, value: $timestamp, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("video.key.frame.description".localized, text: $description)
                }
                
                Section(footer: Text("video.key.frame.edit.note".localized)) {
                    EmptyView()
                }
            }
            .navigationTitle("video.add.key.frame".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        saveKeyFrame()
                    }
                    .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveKeyFrame() {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedDescription.isEmpty else { return }
        
        let keyFrame = VideoKeyFrame(
            timestamp: timestamp,
            description: trimmedDescription,
            video: video
        )
        
        modelContext.insert(keyFrame)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save key frame: \(error)")
        }
    }
}

#Preview {
    KeyFrameEditorView(video: GolfVideo(
        fileName: "sample.mov",
        filePath: "/tmp/sample.mov",
        duration: 30.0,
        clubType: .driver,
        shotType: .tee
    ))
    .modelContainer(for: [GolfCourse.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

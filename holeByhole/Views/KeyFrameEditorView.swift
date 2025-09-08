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
                Section(header: Text("Key Frames")) {
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
                            
                            Text("No Key Frames")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Add key frames to mark important moments in your video")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Key Frames")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
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
        VStack(alignment: .leading, spacing: 4) {
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
                Section(header: Text("Key Frame Details")) {
                    HStack {
                        Text("Timestamp")
                        Spacer()
                        TextField("Time", value: $timestamp, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Description", text: $description)
                }
                
                Section(footer: Text("Key frames help you mark important moments in your golf swing for analysis.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Add Key Frame")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
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

//
//  NewRoundView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct NewRoundView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var courses: [GolfCourse]
    @StateObject private var localizationManager = LocalizationManager.shared
    
    @State private var selectedCourse: GolfCourse?
    @State private var showingCourseSelection = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var isCreatingRound = false
    
    let onRoundCreated: ((GolfCourse, GolfRound) -> Void)?
    
    init(onRoundCreated: ((GolfCourse, GolfRound) -> Void)? = nil) {
        self.onRoundCreated = onRoundCreated
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "flag.2.crossed.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("new.round.title".localized)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("new.round.description".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Course Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("new.round.select.course".localized)
                        .font(.headline)
                    
                    Button(action: {
                        showingCourseSelection = true
                    }) {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(.green)
                            Text(selectedCourse?.name ?? "new.round.no.course".localized)
                                .foregroundColor(selectedCourse == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                // Course Round Information
                if let course = selectedCourse {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("new.round.course.info".localized)
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("new.round.total.rounds".localized)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(course.roundsCount)")
                                    .fontWeight(.semibold)
                            }
                            
                            if let lastRound = course.rounds.sorted(by: { $0.startDate > $1.startDate }).first {
                                HStack {
                                    Text("new.round.last.round".localized)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(lastRound.startDate.formattedDate)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            HStack {
                                Text("new.round.next.number".localized)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "new.round.number.format".localized, course.roundsCount + 1))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
                
                // Create Round Button
                Button(action: {
                    createNewRound()
                }) {
                    HStack {
                        if isCreatingRound {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text(isCreatingRound ? "new.round.creating".localized : "new.round.create".localized)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedCourse == nil ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(selectedCourse == nil || isCreatingRound)
            }
            .padding()
            .navigationTitle("new.round.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCourseSelection) {
                CourseSelectionView(selectedCourse: $selectedCourse)
            }
            .alert("validation.error".localized, isPresented: $showingValidationAlert) {
                Button("common.ok".localized) { }
            } message: {
                Text(validationMessage)
            }
            .onChange(of: localizationManager.currentLanguage) { _, _ in
                // Force view refresh when language changes
            }
        }
    }
    
    private func createNewRound() {
        guard let course = selectedCourse else {
            validationMessage = "new.round.validation.no.course".localized
            showingValidationAlert = true
            return
        }
        
        isCreatingRound = true
        
        // 计算下一个轮次号
        let nextRoundNumber = course.rounds.count + 1
        
        // 创建新轮次
        let newRound = GolfRound(roundNumber: nextRoundNumber, course: course)
        
        // 保存到数据库
        modelContext.insert(newRound)
        
        do {
            try modelContext.save()
            isCreatingRound = false
            
            // 调用回调函数
            onRoundCreated?(course, newRound)
            
            dismiss()
        } catch {
            isCreatingRound = false
            validationMessage = String(format: "new.round.create.failed".localized, error.localizedDescription)
            showingValidationAlert = true
        }
    }
}

#Preview {
    NewRoundView()
        .modelContainer(for: [GolfCourse.self, GolfRound.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

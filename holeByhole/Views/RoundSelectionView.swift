//
//  RoundSelectionView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import SwiftData

struct RoundSelectionView: View {
    let course: GolfCourse
    @Binding var selectedRound: GolfRound?
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewRound = false
    
    var sortedRounds: [GolfRound] {
        course.rounds.sorted { $0.roundNumber > $1.roundNumber }
    }
    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("round.selection.title".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                .sheet(isPresented: $showingNewRound) {
                    newRoundSheet
                }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if sortedRounds.isEmpty {
            EmptyRoundsView(
                title: "round.selection.no.rounds".localized,
                message: "round.selection.create.first".localized
            )
        } else {
            roundsList
        }
    }
    
    private var roundsList: some View {
        List {
            ForEach(sortedRounds) { round in
                RoundRowView(
                    round: round,
                    isSelected: selectedRound?.id == round.id
                ) {
                    selectedRound = round
                    dismiss()
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("common.cancel".localized) {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                showingNewRound = true
            }) {
                Image(systemName: "plus")
                    .font(.title3)
            }
        }
    }
    
    private var newRoundSheet: some View {
        NewRoundView(onRoundCreated: { course, round in
            selectedRound = round
            dismiss()
        }, preselectedCourse: course)
    }
}

struct RoundRowView: View {
    let round: GolfRound
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(round.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
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
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(round.startDate.formattedDate)
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
    RoundSelectionView(
        course: GolfCourse(name: "Sample Course"),
        selectedRound: .constant(nil)
    )
    .modelContainer(for: [GolfCourse.self, GolfRound.self, GolfHole.self, GolfVideo.self, VideoKeyFrame.self], inMemory: true)
}

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
    
    var sortedRounds: [GolfRound] {
        course.rounds.sorted { $0.roundNumber > $1.roundNumber }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if sortedRounds.isEmpty {
                    EmptyRoundsView(
                        title: "round.selection.no.rounds".localized,
                        message: "round.selection.create.first".localized
                    )
                } else {
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
            }
            .navigationTitle("round.selection.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
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
                    
                    Text(round.startDate, style: .date)
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

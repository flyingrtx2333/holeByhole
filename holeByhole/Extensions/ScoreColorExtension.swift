//
//  ScoreColorExtension.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI

// MARK: - Score Color Extension
extension View {
    /// Returns the appropriate color for a golf score based on par
    /// - Parameters:
    ///   - score: The actual score
    ///   - par: The par for the hole
    /// - Returns: Color representing the score quality
    func scoreColor(score: Int, par: Int) -> Color {
        let difference = score - par
        switch difference {
        case ..<0: return .blue // Under par (better than par)
        case 0: return .green // Par
        case 1: return .orange // Bogey
        default: return .red // Double bogey or worse
        }
    }
}

// MARK: - Global Score Color Function
/// Returns the appropriate color for a golf score based on par
/// - Parameters:
///   - score: The actual score
///   - par: The par for the hole
/// - Returns: Color representing the score quality
func scoreColor(score: Int, par: Int) -> Color {
    let difference = score - par
    switch difference {
    case ..<0: 
        // Under par - use different colors based on how much under
        if difference <= -2 {
            return .purple // Eagle or better
        } else {
            return .blue // Birdie
        }
    case 0: return .green // Par
    case 1: return .orange // Bogey
    case 2: return .red // Double bogey
    default: return .red.opacity(0.8) // Triple bogey or worse
    }
}

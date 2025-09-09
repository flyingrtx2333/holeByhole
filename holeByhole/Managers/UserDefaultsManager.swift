//
//  UserDefaultsManager.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import Foundation
import SwiftData

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let currentCourseId = "currentCourseId"
        static let currentRoundId = "currentRoundId"
    }
    
    private init() {}
    
    // MARK: - Current Course
    func setCurrentCourse(_ course: GolfCourse?) {
        if let course = course {
            userDefaults.set(course.id.uuidString, forKey: Keys.currentCourseId)
        } else {
            userDefaults.removeObject(forKey: Keys.currentCourseId)
        }
    }
    
    func getCurrentCourseId() -> UUID? {
        guard let courseIdString = userDefaults.string(forKey: Keys.currentCourseId) else {
            return nil
        }
        return UUID(uuidString: courseIdString)
    }
    
    // MARK: - Current Round
    func setCurrentRound(_ round: GolfRound?) {
        if let round = round {
            userDefaults.set(round.id.uuidString, forKey: Keys.currentRoundId)
        } else {
            userDefaults.removeObject(forKey: Keys.currentRoundId)
        }
    }
    
    func getCurrentRoundId() -> UUID? {
        guard let roundIdString = userDefaults.string(forKey: Keys.currentRoundId) else {
            return nil
        }
        return UUID(uuidString: roundIdString)
    }
    
    // MARK: - Clear Current State
    func clearCurrentState() {
        userDefaults.removeObject(forKey: Keys.currentCourseId)
        userDefaults.removeObject(forKey: Keys.currentRoundId)
    }
    
    // MARK: - Helper Methods
    func findCurrentCourse(in context: ModelContext) -> GolfCourse? {
        guard let courseId = getCurrentCourseId() else { return nil }
        
        let descriptor = FetchDescriptor<GolfCourse>(
            predicate: #Predicate<GolfCourse> { course in
                course.id == courseId
            }
        )
        
        return try? context.fetch(descriptor).first
    }
    
    func findCurrentRound(in context: ModelContext) -> GolfRound? {
        guard let roundId = getCurrentRoundId() else { return nil }
        
        let descriptor = FetchDescriptor<GolfRound>(
            predicate: #Predicate<GolfRound> { round in
                round.id == roundId
            }
        )
        
        return try? context.fetch(descriptor).first
    }
}

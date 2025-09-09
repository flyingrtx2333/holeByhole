//
//  Models.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import Foundation
import SwiftData

// MARK: - Golf Course Model
@Model
final class GolfCourse {
    var id: UUID
    var name: String
    var location: String?
    var isCustom: Bool
    var createdAt: Date
    var rounds: [GolfRound]
    
    // 前九洞标准杆设置
    var frontNinePar: [Int]
    // 后九洞标准杆设置
    var backNinePar: [Int]
    // 球场照片路径
    var photoPath: String?
    
    init(name: String, location: String? = nil, isCustom: Bool = true) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.isCustom = isCustom
        self.createdAt = Date()
        self.rounds = []
        // 默认前九洞和后九洞都是标准4杆洞
        self.frontNinePar = Array(repeating: 4, count: 9)
        self.backNinePar = Array(repeating: 4, count: 9)
        self.photoPath = nil
    }
    
    // 计算属性：获取所有轮次中的球洞总数
    var totalHolesCount: Int {
        return rounds.flatMap { $0.holes }.count
    }
    
    // 计算属性：获取轮次数量
    var roundsCount: Int {
        return rounds.count
    }
    
    // 获取指定球洞的标准杆
    func getPar(for holeNumber: Int, holeSide: HoleSide) -> Int {
        if holeSide == .front && holeNumber >= 1 && holeNumber <= 9 {
            return frontNinePar[holeNumber - 1]
        } else if holeSide == .back && holeNumber >= 1 && holeNumber <= 9 {
            return backNinePar[holeNumber - 1]
        }
        return 4 // 默认4杆洞
    }
    
    // 获取前九洞总标准杆
    var frontNineTotalPar: Int {
        return frontNinePar.reduce(0, +)
    }
    
    // 获取后九洞总标准杆
    var backNineTotalPar: Int {
        return backNinePar.reduce(0, +)
    }
    
    // 获取全场总标准杆
    var totalPar: Int {
        return frontNineTotalPar + backNineTotalPar
    }
}

// MARK: - Golf Round Model
@Model
final class GolfRound {
    var id: UUID
    var roundNumber: Int
    var startDate: Date
    var endDate: Date?
    var isCompleted: Bool
    var weather: String?
    var notes: String?
    var course: GolfCourse?
    var holes: [GolfHole]
    
    init(roundNumber: Int, course: GolfCourse? = nil) {
        self.id = UUID()
        self.roundNumber = roundNumber
        self.startDate = Date()
        self.endDate = nil
        self.isCompleted = false
        self.course = course
        self.holes = []
    }
    
    // 计算属性：获取轮次显示名称
    var displayName: String {
        if let course = course {
            return "\(course.name) - 第\(roundNumber)轮"
        } else {
            return "第\(roundNumber)轮"
        }
    }
    
    // 计算属性：获取轮次状态
    var statusText: String {
        if isCompleted {
            return "已完成"
        } else {
            return "进行中"
        }
    }
    
    // 计算属性：获取已完成的球洞数量
    var completedHolesCount: Int {
        return holes.filter { $0.myStrokes != nil }.count
    }
}

// MARK: - Golf Hole Model
@Model
final class GolfHole {
    var id: UUID
    var holeNumber: Int
    var holeSide: HoleSide?
    var par: Int
    var myStrokes: Int?  // 我的杆数
    var score: Int?      // 成绩（我的杆数 - 标准杆数，自动计算）
    var notes: String?
    var weather: String?
    var mood: String?
    var strategy: String?
    var createdAt: Date
    var videos: [GolfVideo]
    var course: GolfCourse?
    var round: GolfRound?
    
    init(holeNumber: Int, holeSide: HoleSide, par: Int = 4, course: GolfCourse? = nil, round: GolfRound? = nil) {
        self.id = UUID()
        self.holeNumber = holeNumber
        self.holeSide = holeSide
        self.par = par
        self.myStrokes = nil
        self.score = nil
        self.course = course
        self.round = round
        self.createdAt = Date()
        self.videos = []
    }
    
    // 便利初始化方法，用于向后兼容
    convenience init(holeNumber: Int, par: Int = 4, course: GolfCourse? = nil, round: GolfRound? = nil) {
        let holeSide: HoleSide = holeNumber <= 9 ? .front : .back
        self.init(holeNumber: holeNumber, holeSide: holeSide, par: par, course: course, round: round)
    }
    
    // 计算属性：获取完整的洞号显示（如前1洞、后3洞）
    var fullHoleNumber: String {
        let side = holeSide ?? (holeNumber <= 9 ? .front : .back)
        switch side {
        case .front:
            return "前\(holeNumber)洞"
        case .back:
            return "后\(holeNumber)洞"
        }
    }
    
    // 计算属性：获取排序用的数值（前9洞：1-9，后9洞：10-18）
    var sortOrder: Int {
        let side = holeSide ?? (holeNumber <= 9 ? .front : .back)
        switch side {
        case .front:
            return holeNumber
        case .back:
            return holeNumber + 9
        }
    }
    
    // 计算属性：获取成绩显示（我的杆数 - 标准杆数）
    var scoreDisplay: String {
        guard let myStrokes = myStrokes else { return "—" }
        let calculatedScore = myStrokes - par
        if calculatedScore == 0 {
            return "score.par".localized
        } else if calculatedScore == -1 {
            return "score.birdie".localized
        } else if calculatedScore == -2 {
            return "score.eagle".localized
        } else if calculatedScore == 1 {
            return "score.bogey".localized
        } else if calculatedScore == 2 {
            return "score.double.bogey".localized
        } else if calculatedScore > 2 {
            return "+\(calculatedScore)"
        } else {
            return "\(calculatedScore)"
        }
    }
    
    // 方法：更新我的杆数并自动计算成绩
    func updateMyStrokes(_ strokes: Int?) {
        self.myStrokes = strokes
        if let strokes = strokes {
            self.score = strokes - par
        } else {
            self.score = nil
        }
    }
    
    // 方法：更新标准杆数并重新计算成绩
    func updatePar(_ newPar: Int) {
        self.par = newPar
        if let strokes = myStrokes {
            self.score = strokes - newPar
        }
    }
}

// MARK: - Golf Video Model
@Model
final class GolfVideo {
    var id: UUID
    var fileName: String
    var filePath: String
    var thumbnailPath: String?
    var duration: Double
    var clubType: ClubType
    var shotType: ShotType
    var createdAt: Date
    var hole: GolfHole?
    var round: GolfRound?
    var keyFrames: [VideoKeyFrame]
    
    init(fileName: String, filePath: String, duration: Double, clubType: ClubType, shotType: ShotType, hole: GolfHole? = nil, round: GolfRound? = nil) {
        self.id = UUID()
        self.fileName = fileName
        self.filePath = filePath
        self.duration = duration
        self.clubType = clubType
        self.shotType = shotType
        self.hole = hole
        self.round = round
        self.createdAt = Date()
        self.keyFrames = []
    }
}

// MARK: - Video Key Frame Model
@Model
final class VideoKeyFrame {
    var id: UUID
    var timestamp: Double
    var frameDescription: String
    var video: GolfVideo?
    
    init(timestamp: Double, description: String, video: GolfVideo? = nil) {
        self.id = UUID()
        self.timestamp = timestamp
        self.frameDescription = description
        self.video = video
    }
}

// MARK: - Enums
enum HoleSide: String, CaseIterable, Codable {
    case front = "front"
    case back = "back"
    
    var displayName: String {
        switch self {
        case .front: return "hole.side.front".localized
        case .back: return "hole.side.back".localized
        }
    }
}

enum ClubType: String, CaseIterable, Codable {
    case driver = "driver"
    case wood = "wood"
    case iron = "iron"
    case wedge = "wedge"
    case putter = "putter"
    case hybrid = "hybrid"
    
    var displayName: String {
        switch self {
        case .driver: return "club.driver".localized
        case .wood: return "club.wood".localized
        case .iron: return "club.iron".localized
        case .wedge: return "club.wedge".localized
        case .putter: return "club.putter".localized
        case .hybrid: return "club.hybrid".localized
        }
    }
}

enum ShotType: String, CaseIterable, Codable {
    case tee = "tee"
    case fairway = "fairway"
    case approach = "approach"
    case chip = "chip"
    case putt = "putt"
    case bunker = "bunker"
    
    var displayName: String {
        switch self {
        case .tee: return "shot.tee".localized
        case .fairway: return "shot.fairway".localized
        case .approach: return "shot.approach".localized
        case .chip: return "shot.chip".localized
        case .putt: return "shot.putt".localized
        case .bunker: return "shot.bunker".localized
        }
    }
}

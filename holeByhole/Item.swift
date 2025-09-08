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
    var holes: [GolfHole]
    
    init(name: String, location: String? = nil, isCustom: Bool = true) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.isCustom = isCustom
        self.createdAt = Date()
        self.holes = []
    }
}

// MARK: - Golf Hole Model
@Model
final class GolfHole {
    var id: UUID
    var holeNumber: Int
    var holeSide: HoleSide?
    var par: Int
    var score: Int?
    var notes: String?
    var weather: String?
    var mood: String?
    var strategy: String?
    var createdAt: Date
    var videos: [GolfVideo]
    var course: GolfCourse?
    
    init(holeNumber: Int, holeSide: HoleSide, par: Int = 4, course: GolfCourse? = nil) {
        self.id = UUID()
        self.holeNumber = holeNumber
        self.holeSide = holeSide
        self.par = par
        self.course = course
        self.createdAt = Date()
        self.videos = []
    }
    
    // 便利初始化方法，用于向后兼容
    convenience init(holeNumber: Int, par: Int = 4, course: GolfCourse? = nil) {
        let holeSide: HoleSide = holeNumber <= 9 ? .front : .back
        self.init(holeNumber: holeNumber, holeSide: holeSide, par: par, course: course)
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
    var keyFrames: [VideoKeyFrame]
    
    init(fileName: String, filePath: String, duration: Double, clubType: ClubType, shotType: ShotType, hole: GolfHole? = nil) {
        self.id = UUID()
        self.fileName = fileName
        self.filePath = filePath
        self.duration = duration
        self.clubType = clubType
        self.shotType = shotType
        self.hole = hole
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

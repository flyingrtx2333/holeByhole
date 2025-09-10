//
//  holeByholeTests.swift
//  holeByholeTests
//
//  Created by 向钧升 on 2025/9/8.
//

import Testing
@testable import holeByhole

struct holeByholeTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func locationCoordinateCreation() async throws {
        let location = LocationCoordinate(
            latitude: 39.9042,
            longitude: 116.4074,
            address: "天安门广场",
            city: "北京",
            country: "中国"
        )
        
        #expect(location.latitude == 39.9042)
        #expect(location.longitude == 116.4074)
        #expect(location.displayAddress == "天安门广场")
        #expect(location.shortAddress == "北京")
    }
    
    @Test func golfCourseWithLocation() async throws {
        let location = LocationCoordinate(
            latitude: 39.9042,
            longitude: 116.4074,
            address: "天安门广场",
            city: "北京",
            country: "中国"
        )
        
        let course = GolfCourse(name: "测试球场", location: location)
        
        #expect(course.name == "测试球场")
        #expect(course.location?.latitude == 39.9042)
        #expect(course.location?.longitude == 116.4074)
        #expect(course.hasValidLocation == true)
        #expect(course.locationDisplayText == "天安门广场")
    }

}

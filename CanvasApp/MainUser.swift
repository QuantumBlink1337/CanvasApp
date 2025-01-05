//
//  Self.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/17/24.
//

import Foundation


/// Static struct that stores the information relevant to the current connected user using the application
struct MainUser {
    static var selfUser: User? = nil
    static var selfCourseWrappers: [CourseWrapper] = []
    static var selfCourseColors: UserColorCodes? = nil
}

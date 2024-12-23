//
//  GroupPanel.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/22/24.
//

import Foundation
import SwiftUI



struct GroupPanel : View {
    private var group: Group
    
    let image_width: CGFloat = 170
    let image_height: CGFloat = 80
    
    let courseWrapper: CourseWrapper?
    
    
    
    init(group: Group) {
        self.group = group
        
        self.courseWrapper = MainUser.selfCourseWrappers.first {
            $0.course.id == group.courseID ?? 0
        }
    }
    
    var body : some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .frame(width: image_width, height: image_height)
                    .foregroundStyle(HexToColor(courseWrapper?.course.color ?? "#000000") ?? .accentColor)
                
            }
            Text(group.name)
                .font(.subheadline) // Display course name
                .multilineTextAlignment(.leading)
                .lineLimit(2, reservesSpace: true)
                .padding(.leading, 1.0)
            Text(courseWrapper?.course.name ?? "Missing Context")
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .lineLimit(2, reservesSpace: true)
                .padding(.leading, 1.0)
                .foregroundStyle(.gray)

                

            
        }
        .background()

        
    }
    
}

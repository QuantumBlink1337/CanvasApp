//
//  AssignmentMasterView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/9/24.
//

import SwiftUI


struct AssignmentMasterView: View {
    
    var courseWrapper: CourseWrapper
    @State private var dateIsExpanded: Set<String>
    @State private var assignIsExpanded: Set<String>
    
    let color: Color
    
    init(courseWrapper: CourseWrapper) {
        self.courseWrapper = courseWrapper
        _dateIsExpanded = State(initialValue: Set((courseWrapper.course.datedAssignments?.keys.map{"\($0)"})!))
        _assignIsExpanded = State(initialValue: Set(courseWrapper.course.assignments.map{$0.title}))
        color = HexToColor(courseWrapper.course.color) ?? .black
        
    }
    @ViewBuilder
    private func buildAssignmentSection(datePriority: DatePriority) -> some View {
        let assignments = courseWrapper.course.datedAssignments![datePriority]!
            DisclosureGroup(isExpanded: Binding<Bool> (
                get: {
                    return dateIsExpanded.contains("\(datePriority)")
                },
                set: { isExpanding in
                    if (isExpanding) {
                        dateIsExpanded.insert("\(datePriority)")
                    }
                    else {
                        dateIsExpanded.remove("\(datePriority)")
                    }
                }
            ),
                    content: {
                        ForEach(assignments) { assignment in
                            
                            DisclosureGroup(isExpanded: Binding<Bool> (
                                get: {
                                    return assignIsExpanded.contains("\(datePriority)")
                                },
                                set: { isExpanding in
                                    if (isExpanding) {
                                        assignIsExpanded.insert("\(datePriority)")
                                    }
                                    else {
                                        assignIsExpanded.remove("\(datePriority)")
                                    }
                                }
                            ),
                            content: {
                                Text("Test")
                            },
                            label: {
                                VStack(alignment: .leading) {
                                  
                                        HStack(alignment: .top) {
                                            Image(systemName: "list.clipboard.fill")
                                                .resizable()
                                                .frame(width: 25, height: 40)
                                                .foregroundStyle(color)
//                                                .padding(.top)
                                                .padding(.trailing)
                                            VStack(alignment: .leading) {
                                                Text(assignment.title)
                                                    .font(.body)
                                                if (assignment.dueAt != nil) {
                                                    Text("Due at " + formattedDate(for: assignment.dueAt, omitTime: false))
                                                        .font(.caption)
                                                }
                                            }
                                            Spacer()
                                            ZStack {
                                                Text("\(Int(assignment.pointsPossible!))")
                                                    .font(.callout)
                                                    .foregroundStyle(.white)
                                            }
                                            
                                            
                                            
                                        }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                            }
                            )
                            .tint(HexToColor(courseWrapper.course.color))
                                
                    
                                
                            
                            
                            
                        }
            },
                            label: {
                    let prioString = if (datePriority == .dueSoon) {"Due Soon"}
                    else if (datePriority == .past) {"Past"}
                    else if (datePriority == .upcoming) {"Upcoming"}
                    else {"Could not load priority"}
                            Text("\(prioString)")
                            .font(.subheadline)
                            .fontWeight(.heavy)
                
                
            }
            )
        
    }
    
    
    
    var body: some View {
        VStack {
            
            Text("Assignments")
                .font(.title)
                .fontWeight(.heavy)
            List(DatePriority.allCases) { datePriority in
                buildAssignmentSection(datePriority: datePriority)

            }
            .listStyle(.sidebar)
//            ScrollView {
//                ForEach(DatePriority.allCases, id: \.self) { datePriority in
//                }
//            }
            
        }
    }
    
}
#Preview {
    // Sample test data for Course and Assignments
    let sampleAssignments = [
        Assignment(
            id: 1,
            title: "Assignment 1",
            body: "This is the body of assignment 1",
            createdAt: Date(),
            updatedAt: Date(),
            dueAt: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
            lockedAt: nil,
            courseID: 101,
            pointsPossible: 100
        ),
        Assignment(
            id: 2,
            title: "Assignment 2",
            body: "This is the body of assignment 2",
            createdAt: Date(),
            updatedAt: Date(),
            dueAt: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            lockedAt: nil,
            courseID: 101,
            pointsPossible: 50
        ),
        Assignment(
            id: 3,
            title: "Assignment 3",
            body: "This is the body of assignment 3",
            createdAt: Date(),
            updatedAt: Date(),
            dueAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            lockedAt: nil,
            courseID: 101,
            pointsPossible: 75
        )
    ]

    // Sample Course with datedAssignments
    let sampleCourse = Course(
            name: "Sample Course",
            courseCode: "SC101",
            id: 101,
            color: "#FF5733", // Sample orange color
            assignments: sampleAssignments,
            datedAssignments: [
                .dueSoon: [sampleAssignments[0]],
                .upcoming: [sampleAssignments[1]],
                .past: [sampleAssignments[2]]
            ]
        )

    // Sample CourseWrapper
    let courseWrapper = CourseWrapper(course: sampleCourse)

    return AssignmentMasterView(courseWrapper: courseWrapper)
}

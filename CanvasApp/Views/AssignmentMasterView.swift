//
//  AssignmentMasterView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/9/24.
//

import SwiftUI


struct AssignmentMasterView: View {
    
    var courseWrapper: CourseWrapper
    @State private var isExpanded: Set<String>
    
    init(courseWrapper: CourseWrapper) {
        self.courseWrapper = courseWrapper
        _isExpanded = State(initialValue: Set((courseWrapper.course.datedAssignments?.keys.map{"\($0)"})!))
        
    }
    @ViewBuilder
    private func buildAssignmentSection(datePriority: DatePriority) -> some View {
        let assignments = courseWrapper.course.datedAssignments![datePriority]!
        VStack() {
           
            
            Section(isExpanded: Binding<Bool> (
                get: {
                    return isExpanded.contains("\(datePriority)")
                },
                set: { isExpanding in
                    if (isExpanding) {
                        isExpanded.insert("\(datePriority)")
                    }
                    else {
                        isExpanded.remove("\(datePriority)")
                    }
                }
            ),
                    content: {
                VStack(alignment: .leading) {
                    ScrollView {
                        ForEach(assignments) { assignment in
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundStyle(HexToColor(courseWrapper.course.color) ?? .black)
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading) {
                                        Text(assignment.title)
                                            .foregroundStyle(.white)
                                        if (assignment.dueAt != nil) {
                                            Text("Due at " + formattedDate(for: assignment.dueAt, omitTime: false))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    Spacer()
                                    ZStack {
                                        Circle()
                                        Text("Points: \(assignment.pointsPossible ?? 0)")
                                            .foregroundStyle(.white)
                                    }
                                    
                                    
                                    
                                }.padding(.all)
                                
                            }.padding(.leading)
                            .padding(.trailing)
                            
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 5)
                        }/*.frame(minHeight: 400)*/

                    }
                }
            },
                    header: {
                VStack(alignment: .center) {
                    let prioString = if (datePriority == .dueSoon) {"Due Soon"}
                    else if (datePriority == .past) {"Past"}
                    else if (datePriority == .upcoming) {"Upcoming"}
                    else {"Could not load priority"}
                            Text("\(prioString)")
                            .font(.subheadline)
                            .fontWeight(.heavy)
                }
                
            }
            )
        }
    }
    
    
    
    var body: some View {
        VStack {
            Text("Assignments")
                .font(.title)
                .fontWeight(.heavy)
            ScrollView {
                ForEach(DatePriority.allCases, id: \.self) { datePriority in
                    buildAssignmentSection(datePriority: datePriority)
                }
            }
            
        }
    }
    
}

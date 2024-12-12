//
//  AssignmentMasterView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/9/24.
//

import SwiftUI


struct AssignmentMasterView: View {
    
    var courseWrapper: CourseWrapper
    @State private var dateIsExpanded: Set<DatePriority>
    @State private var assignIsExpanded: Set<String>
    
    let color: Color
    
    init(courseWrapper: CourseWrapper) {
        self.courseWrapper = courseWrapper
        _dateIsExpanded = State(initialValue: Set(courseWrapper.course.datedAssignments!.keys))
        _assignIsExpanded = State(initialValue: Set())
        color = HexToColor(courseWrapper.course.color) ?? .black
        
        
        // Create and configure the navigation bar appearance
       let appearance = UINavigationBarAppearance()
       appearance.configureWithOpaqueBackground()
        appearance.shadowColor = .clear
       
       // Set the navigation bar background color (optional)
        appearance.backgroundColor = UIColor.init(hex: courseWrapper.course.color)
//        appearance.backButtonAppearance = UIColor.white
        
       
       // Customize the title text attributes (color, font)
       appearance.titleTextAttributes = [
           .foregroundColor: UIColor.white,
           .font: UIFont.boldSystemFont(ofSize: 24) // You can customize the font here
       ]
       
       // Apply the appearance to the navigation bar
       UINavigationBar.appearance().standardAppearance = appearance
       UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        
        
    }
    @ViewBuilder
    private func buildAssignmentGlanceView(for assignment: Assignment) -> some View {
//        GeometryReader { geometry in
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    ZStack(alignment: .center) {
                        Circle()
                            .stroke(color, lineWidth: 5)
                            .frame(width: 50, height: 50)
                        Text(String(assignment.pointsPossible ?? 0))
                    }
                    Text("Point Total")
                    Spacer()
                }
                
            }
//        }        .background(.blue)

        
        
    }
    @ViewBuilder
    private func buildAssignmentSection(datePriority: DatePriority) -> some View {
        let assignments = courseWrapper.course.datedAssignments![datePriority]!
            ForEach(assignments) { assignment in
                DisclosureGroup(isExpanded: Binding<Bool> (
                    get: {
                        return assignIsExpanded.contains("\(assignment.title)")
                    },
                    set: { isExpanding in
                        if (isExpanding) {
                            assignIsExpanded.insert("\(assignment.title)")
                        }
                        else {
                            assignIsExpanded.remove("\(assignment.title)")
                        }
                    }
                ),
                                content: {
                    VStack(alignment: .center) {
                        buildAssignmentGlanceView(for: assignment)
                    }
                },
                                label: {
                    VStack(alignment: .leading) {
                        
                        HStack(alignment: .top) {
                            Image(systemName: "list.clipboard.fill")
                                .resizable()
                                .frame(width: 25, height: 40)
                                .foregroundStyle(color)
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
    }
    
    
    
    var body: some View {
        GeometryReader  { geometry in
            VStack {
                VStack {
//                    Text("Assignments")
//                        .font(.title)
//                        .fontWeight(.heavy)
//                        .foregroundStyle(.white)
//                        .frame(width: geometry.size.width, height: 50)
                    HStack {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 5)
                                .frame(width: 45, height: 45)
                            Text(courseWrapper.course.enrollment?.grade?.currentGrade ?? "X")
                                .font(.title2)
                                .foregroundStyle(.white)
                           
                        }
                        Text(String(courseWrapper.course.enrollment?.grade?.currentScore ?? 0.00) + "%")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    Text("Current Grade")
                        .foregroundStyle(.white)
                        .font(.title3)
                    
                   
                }
                .frame(width: geometry.size.width)
                .padding(.top, 15)
                .background(color)
                   
                List {
                    ForEach(DatePriority.allCases) { datePriority in
                        Section(isExpanded: Binding<Bool> (
                            get: {
                                return dateIsExpanded.contains(datePriority)
                            },
                            set: { isExpanding in
                                if (isExpanding) {
                                    dateIsExpanded.insert(datePriority)
                                }
                                else {
                                    dateIsExpanded.remove(datePriority)
                                }
                            }
                        ),
                            
                        content: {
                            buildAssignmentSection(datePriority: datePriority)
                        },
                        header:
                            {
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
                
                }
                .listStyle(.sidebar)
                .background(color)
                .padding(.top)

            }

        }
        .background(color)
        .navigationTitle("Assignments")
    }
    
}
#Preview {
    // Create sample assignments
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

    // Create sample datedAssignments
    let sampleDatedAssignments: [DatePriority: [Assignment]] = [
        .dueSoon: [sampleAssignments[0]],
        .upcoming: [sampleAssignments[1]],
        .past: [sampleAssignments[2]]
    ]
    let sampleGrade = Grade(currentGrade: "A-", currentScore: 91.50)

    // Create a sample enrollment
    let sampleEnrollment = Enrollment(
        id: 1,
        courseID: 101,
        enrollmentState: "active",
        enrollmentType: .StudentEnrollment,
        grade: sampleGrade
    )

    // Create a sample course
    let sampleCourse = Course(
        name: "Sample Course",
        courseCode: "SC101",
        id: 101,
        color: "#FF5733",
        assignments: sampleAssignments,
        datedAssignments: sampleDatedAssignments,
        enrollment: sampleEnrollment
    )

    // Wrap the sample course in a CourseWrapper
    let courseWrapper = CourseWrapper(course: sampleCourse)

    // Return the AssignmentMasterView for the preview
    return AssignmentMasterView(courseWrapper: courseWrapper)
}

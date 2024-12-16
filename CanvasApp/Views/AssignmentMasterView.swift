//
//  AssignmentMasterView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/9/24.
//

import SwiftUI
import Charts
struct ScoreDataPoint : Identifiable{
    var id: UUID
    let name: String
    let value: Float
    let type: String
}


struct AssignmentMasterView: View {
    
    var courseWrapper: CourseWrapper
    @State private var dateIsExpanded: Set<DatePriority>
    @State private var assignIsExpanded: Set<String>
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    let color: Color
    
    @Binding private var navigationPath: NavigationPath
    
    var assignmentDates: [Assignment : String] = [ : ]
    
    init(courseWrapper: CourseWrapper, navigationPath: Binding<NavigationPath>) {
        self.courseWrapper = courseWrapper
        _dateIsExpanded = State(initialValue: Set(courseWrapper.course.datedAssignments!.keys))
        _assignIsExpanded = State(initialValue: Set())
        color = HexToColor(courseWrapper.course.color) ?? .black
        self._navigationPath = navigationPath
        
        for assignment in courseWrapper.course.assignments {
            let formattedDate = formattedDate(for: assignment.dueAt ?? Date(), format: .longFormWithTime)
            assignmentDates.updateValue(formattedDate, forKey: assignment)
        }
       
        
    
        
    }
    @ViewBuilder
    private func buildScoreStatistic(for assignment: Assignment) -> some View {
            let scoreStatistic = assignment.scoreStatistic!
            
        let data: [ScoreDataPoint] = [
                ScoreDataPoint(id: UUID(), name: "Max", value: scoreStatistic.max, type: "Computed"),
                ScoreDataPoint(id: UUID(), name: "Min", value: scoreStatistic.min, type: "Computed"),
                ScoreDataPoint(id: UUID(), name: "Mean", value: scoreStatistic.mean, type: "Computed"),
                ScoreDataPoint(id: UUID(), name: "LowerQuart", value: scoreStatistic.lowerQuartile, type: "Quartile"),
                ScoreDataPoint(id: UUID(), name: "UpperQuart", value: scoreStatistic.upperQuartile, type: "Quartile"),
                ScoreDataPoint(id: UUID(), name: "Zero", value: 0, type: "Computed"),
                
                ScoreDataPoint(id: UUID(), name: "Score", value: Float((assignment.currentSubmission?.score)!), type: "Real")]
                Chart(data) {
                   
                    if let maxValue = data.first(where: { $0.name == "Max" })?.value {
                            RuleMark(
                                xStart: .value("Min Value", 0),
                                xEnd: .value("Max Value", maxValue),
                                y: .value("Fixed", 0)
                            )
                            .foregroundStyle(Color.gray)
                            .lineStyle(StrokeStyle(lineWidth: 2)) // Dashed line for emphasis
                        }
                    if let minValue = data.first(where: { $0.name == "Min" })?.value,
                           let maxValue = data.first(where: { $0.name == "Max" })?.value {
                            RuleMark(
                                xStart: .value("Min Value", minValue),
                                xEnd: .value("Max Value", maxValue),
                                y: .value("Fixed", 0)
                            )
                            .foregroundStyle(Color.black)
                            .lineStyle(StrokeStyle(lineWidth: 2)) // Dashed line for emphasis
                        }
                    if let minValue = data.first(where: { $0.name == "LowerQuart" })?.value,
                           let maxValue = data.first(where: { $0.name == "UpperQuart" })?.value {
                            RuleMark(
                                xStart: .value("Min Value", minValue),
                                xEnd: .value("Max Value", maxValue),
                                y: .value("Fixed", 0)
                            )
                            .foregroundStyle(Color.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2)) // Dashed line for emphasis
                        }
                    if ($0.type == "Computed") {
                        PointMark(
                            x: .value($0.name, $0.value)
                        )
                        .foregroundStyle(color)
                        .symbol(.plus)
                        .symbolSize(100)

                    }
                    else if ($0.type == "Quartile") {
                        PointMark(
                            x: .value($0.name, $0.value)
                        )
                        .foregroundStyle(.blue)
                        .symbol(.diamond)
                        .symbolSize(100)
                    }
                    else {
                        PointMark(
                            x: .value($0.name, $0.value)
                        )
                        .foregroundStyle(color)
                        .symbolSize(150)
                    }
                    
                }.frame(height: 40)
                .chartYAxis(.hidden)
                .chartXScale(domain: 0...scoreStatistic.max)
                .chartXAxis {
                    AxisMarks(values: [scoreStatistic.min, scoreStatistic.mean, scoreStatistic.max]) { value in

                        AxisTick()
                            
                    }
                }
        HStack {
            Text("Min: \(scoreStatistic.min, specifier: "%.2f")")
                .font(.caption)
            Spacer()
            Text("Mean: \(scoreStatistic.mean, specifier: "%.2f")")
                .font(.caption)

            Spacer()
            Text("Max: \(scoreStatistic.max, specifier: "%.2f")")
                .font(.caption)
        }
        HStack {
            Text("Lower Quartile: \(scoreStatistic.lowerQuartile, specifier: "%.2f")")
                .font(.caption)
            Spacer()
            Text("Median: \(scoreStatistic.median, specifier: "%.2f")")
                .font(.caption)

            Spacer()
            Text("Upper Quartile: \(scoreStatistic.upperQuartile, specifier: "%.2f")")
                .font(.caption)
        }

        

        
    }
    @ViewBuilder
    private func buildAssignmentGlanceView(for assignment: Assignment) -> some View {
//        GeometryReader { geometry in
        if (assignment.currentSubmission?.score == nil) {
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    ZStack(alignment: .center) {
                        Circle()
                            .stroke(color, lineWidth: 5)
                            .frame(width: 50, height: 50)
                        Text(String(assignment.pointsPossible ?? 0))
                    }
                    Text("Points Possible")
                    Spacer()
                }
                
            }
        }
        else {
            VStack {
                HStack {
                    ZStack(alignment: .center) {
                        Circle()
                            .stroke(color, lineWidth: 5)
                            .frame(width: 50, height: 50)
                        Text(String(assignment.currentSubmission?.score ?? 0))
                    }
                    .contextMenu(ContextMenu(menuItems: {
                        /*@START_MENU_TOKEN@*/Text("Menu Item 1")/*@END_MENU_TOKEN@*/
                        
                    }))
                    Text("Out of \(assignment.pointsPossible!, specifier: "%.1f")")
                    Spacer()
                }
                
                if assignment.scoreStatistic != nil {
                    buildScoreStatistic(for: assignment)
                    

                }

            }
        }
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
                                    Text(assignmentDates[assignment] ?? "XX")
                                        .font(.caption)
                                }
                            }
                            Spacer()
                            Spacer()
                            VStack {
                                    if (assignment.currentSubmission?.score != nil) {
                                        ZStack {
                                            Circle()
                                                .stroke(Color.green, lineWidth: 5)
                                                .frame(width: 40, height: 40)
                                                
                                            Image(systemName: "person.fill.checkmark")
                                                .resizable()
                                                .frame(width: 20, height: 15)                                        
                                                .foregroundStyle(.green)
                                        }.padding(.top, 4)
                                            .padding(.trailing, 10)
                                       

                                        
                                    }

                                
                                
                            }
                            

                            
                            
                            
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                }
                )
                .tint(HexToColor(courseWrapper.course.color))
            }
    }
    @ViewBuilder
    private func buildGradeHeader() -> some View{
        VStack {
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
        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
        .padding(.top, 15)
        .background(color)
    }
    @ViewBuilder
    private func buildAssignmentList() -> some View {
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
    
    
    var body: some View {
            VStack {
                buildGradeHeader()
                buildAssignmentList()
            }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                GlobalTracking.BackButton(binding: presentationMode, navigationPath: $navigationPath)
            }
            ToolbarItem(placement: .principal) {
                Text("Assignments")
                    .foregroundStyle(.white)
                    .font(.title)
                    .fontWeight(.heavy)
            }
        }
        .background(color)
    }
    
}
#Preview {
    let scoreStatistic = ScoreStatistic(min: 52.3, max: 101.8, mean: 78.1, upperQuartile: 80, median: 11, lowerQuartile: 40)
    let submission = Submission(id: 100, score: 79.75, assignmentID: 1, userID: 105, graderID: 1, attempt: 1, late: false , missing: false)
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
            pointsPossible: 100,
            currentSubmission: submission, scoreStatistic: scoreStatistic
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
    return AssignmentMasterView(courseWrapper: courseWrapper, navigationPath: Binding.constant(NavigationPath()))
}

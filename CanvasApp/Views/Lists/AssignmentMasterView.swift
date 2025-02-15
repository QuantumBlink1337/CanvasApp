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
@ViewBuilder
func buildScoreStatistic(for assignment: Assignment, color: Color = .black) -> some View {
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
        
    }
    .frame(height: 40)
    .chartYAxis(.hidden)
    .chartXScale(domain: 0...scoreStatistic.max)
    .chartXAxis {
        AxisMarks(values: [scoreStatistic.min, scoreStatistic.mean, scoreStatistic.max]) { value in
            AxisTick()
        }
    }
    HStack {
        Text("Min: \(scoreStatistic.min.clean)")
            .font(.caption)
        Spacer()
        Text("Mean: \(scoreStatistic.mean.clean)")
            .font(.caption)

        Spacer()
        Text("Max: \(scoreStatistic.max.clean)")
            .font(.caption)
    }
    HStack {
        Text("Lower Quartile: \(scoreStatistic.lowerQuartile.clean)")
            .font(.caption)
        Spacer()
        Text("Median: \(scoreStatistic.median.clean)")
            .font(.caption)

        Spacer()
        Text("Upper Quartile: \(scoreStatistic.upperQuartile.clean)")
            .font(.caption)
    }

    

    
}





struct AssignmentMasterView: View {
    
    var courseWrapper: CourseWrapper
    @State private var dateIsExpanded: Set<DatePriority>
    @State private var assignIsExpanded: Set<String>
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    let color: Color
    
    @Binding private var navigationPath: NavigationPath
    
    @State private var selectedAssignment: Assignment? = nil
    @State private var loadAssignmentPage: Bool = false
    @State private var showMenu = false

    
    var assignmentDates: [Assignment : String] = [ : ]
    
    let enrollment: Enrollment?
    
    init(courseWrapper: CourseWrapper, navigationPath: Binding<NavigationPath>) {
        self.courseWrapper = courseWrapper
        _dateIsExpanded = State(initialValue: Set(courseWrapper.course.datedAssignments!.keys))
        _assignIsExpanded = State(initialValue: Set())
        color = HexToColor(courseWrapper.course.color) ?? .black
        self._navigationPath = navigationPath
        let assignments = courseWrapper.course.datedAssignments?.values.flatMap {$0} ?? []
        
        for assignment in  assignments{
            let formattedDate = formattedDate(for: assignment.dueAt ?? Date(), format: .longFormWithTime)
            assignmentDates.updateValue(formattedDate, forKey: assignment)
        }
        self.enrollment = MainUser.selfUser?.enrollments.first(where: {
            $0.courseID == courseWrapper.course.id &&
            $0.enrollmentType == .StudentEnrollment
        })
    
        
    }
    
    struct ScorePoint {
        var category: String
        var points: Float
    }
    
    @ViewBuilder
    func buildAssignmentScoreChart(for assignment: Assignment, color: Color) -> some View {
        HStack() {
            ZStack {
                let scorePoints: [ScorePoint] = [
                    .init(category: "PointsGained", points: assignment.currentSubmission?.score ?? 0),
                    .init(category: "PointsMissed", points: (assignment.pointsPossible ?? 0) - (assignment.currentSubmission?.score ?? 0))
                    
                ]
                Chart(scorePoints, id: \.category) { item in
                    SectorMark (
                        angle: .value("Points", item.points),
                        innerRadius: .ratio(0.8),
                        angularInset: 2
                        
                    )
                    .foregroundStyle(by: .value("Category", item.category))
                }
                .chartForegroundStyleScale([
                    "PointsGained": color,
                    "PointsMissed": .white
                ])
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .frame(width: 80, height: 80)
                Text("\(assignment.currentSubmission?.score?.clean ?? "0")")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                
                Spacer()
            }
            Text("Out of \(assignment.pointsPossible?.clean ?? "0")")

        }
    }
     
    
    @ViewBuilder
    func buildAssignmentScoreReport(for assignment: Assignment, color: Color) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Attempt: \(assignment.currentSubmission?.attempt ?? 0)")
                    .font(.footnote)

                Spacer()
                Text(formattedDate(for: assignment.currentSubmission?.submittedAt ?? Date(), format: .mediuMFormWithTime))
                    .font(.footnote)

            }
            buildAssignmentScoreChart(for: assignment, color: color)
            
            if assignment.scoreStatistic != nil {
                buildScoreStatistic(for: assignment, color: color)
            }
        }
    }
    
    
    @ViewBuilder
    func buildAssignmentGlanceView(for assignment: Assignment) -> some View {
//        GeometryReader { geometry in
        if (assignment.currentSubmission?.score == nil) {
            VStack(alignment: .center) {
                HStack {
                    ZStack(alignment: .center) {
                        Circle()
                            .stroke(color, lineWidth: 5)
                            .frame(width: 50, height: 50)
                        Text(String(assignment.pointsPossible?.clean ?? "0"))
                    }
                    Text("Points Possible")
                    Spacer()
                    if (assignment.currentSubmission == nil) {
                        Text("No submission")
                    }
                }
                
                
            }
        }
        else {
            buildAssignmentScoreReport(for: assignment, color: color)
        }
    }
    @ViewBuilder
    private func buildAssignmentSection(datePriority: DatePriority) -> some View {
        let assignments = courseWrapper.course.datedAssignments![datePriority]!
            ForEach(assignments) { assignment in
                let isExpanded = Binding<Bool> (
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
                )
                DisclosureGroup(
                    isExpanded: isExpanded,
                                content: {
                    VStack(alignment: .center) {
                        buildAssignmentGlanceView(for: assignment)
                    }
                },
                                label: {
                    VStack(alignment: .leading) {
                        
                        HStack(alignment: .center) {
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
                            VStack() {
                                if (assignment.currentSubmission?.score != nil) {
                                    ZStack {
                                        Circle()
                                            .stroke(color, lineWidth: 3)
                                            .frame(width: 30, height: 30)
                                        Image(systemName: "person.fill.checkmark")
                                            .resizable()
                                            .frame(width: 20, height: 15)
                                            .foregroundStyle(color)
                                    }
                                    .padding(.trailing)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onTapGesture {
                        withAnimation {
                            isExpanded.wrappedValue.toggle()
                        }
                    }
                }
                ).simultaneousGesture(LongPressGesture().onEnded {_ in
                    selectedAssignment = assignment
                    loadAssignmentPage = true
                })
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
                    Text(enrollment?.grade?.currentGrade ?? "X")
                        .font(.title2)
                        .foregroundStyle(.white)
                   
                }
                Text(String(enrollment?.grade?.currentScore?.clean ?? "0") + "%")
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
                    Text("\(datePriority.description)")
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
            }.navigationDestination(isPresented: $loadAssignmentPage, destination: {
                if (selectedAssignment != nil) {
                    AssignmentPageView(courseWrapper: courseWrapper, assignment: selectedAssignment!, navigationPath: $navigationPath)

                }
            })
            .overlay {
                if showMenu {
                    SideMenuView(isPresented: $showMenu, navigationPath: $navigationPath)
                        .zIndex(1) // Make sure it overlays above the content
                        .transition(.move(edge: .leading))
                        .frame(maxHeight: .infinity) // Full screen height
                }
            }
        .navigationBarBackButtonHidden(true)
        .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if (!showMenu) {
                        BackButton(binding: presentationMode, navigationPath: $navigationPath, action: {showMenu.toggle()})

                    }
                    else {
                        Color.clear.frame(height: 30)
                    }
                }
                ToolbarItem(placement: .principal) {
                    if (!showMenu) {
                        Text("Assignments")
                            .foregroundStyle(.white)
                            .font(.title)
                            .fontWeight(.heavy)
                    }
                    else {
                        Color.clear.frame(height: 30)

                    }
                }
        }
        .background(color)
    }
    
}

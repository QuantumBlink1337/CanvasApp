//
//  PeopleView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/17/24.
//

import SwiftUI

struct PeopleView: View {
    var courseWrapper: CourseWrapper
    let color: Color
    
    @Binding private var navigationPath: NavigationPath
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var enrollmentTypeIsExpanded: Set<EnrollmentType>
    @State private var userIsExpanded: Set<Int>
    
    init(courseWrapper: CourseWrapper, navigationPath: Binding<NavigationPath>) {
        self.courseWrapper = courseWrapper
        self.color = HexToColor(courseWrapper.course.color) ?? .black
        self._navigationPath = navigationPath
        let set: Set = [EnrollmentType.TaEnrollment, EnrollmentType.TeacherEnrollment]
        _enrollmentTypeIsExpanded = State(initialValue: set)
        _userIsExpanded = State(initialValue: Set())
        

        
    }
    
    
    
    @ViewBuilder
    private func buildUserView(users: [User]) -> some View {
            ForEach(users) { user in
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            let userAvatarURL: String = user.avatarURL ?? "Missing"
                            buildAsyncImage(urlString: userAvatarURL, imageWidth: GlobalTracking.avatarWidth, imageHeight: GlobalTracking.avatarHeight, shape: .circle)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name ?? "Missing name")
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(Color.black)
                                Text(user.pronouns ?? "")
                                    .font(.footnote)
                                    .foregroundStyle(Color.black)

                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                .tint(HexToColor(courseWrapper.course.color))
            }
    }
    
    
    @ViewBuilder
    private func buildPeopleList() -> some View {
        List {
            ForEach(EnrollmentType.allCases) { enrollmentType in
                Section(isExpanded: Binding<Bool> (
                    get: {
                        return enrollmentTypeIsExpanded.contains(enrollmentType)
                    },
                    set: { isExpanding in
                        if (isExpanding) {
                            enrollmentTypeIsExpanded.insert(enrollmentType)
                        }
                        else {
                            enrollmentTypeIsExpanded.remove(enrollmentType)
                        }
                    }
                ),
                    
                content: {
                    buildUserView(users: courseWrapper.course.usersInCourse[enrollmentType]!)
                },
                header:
                    {
                
                    Text("\(enrollmentType.rawValue.replacingOccurrences(of: "Enrollment", with: ""))")
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
            buildPeopleList()
        }
    .navigationBarBackButtonHidden(true)
    .toolbar {
        ToolbarItem(placement: .topBarLeading) {
            BackButton(binding: presentationMode, navigationPath: $navigationPath)
        }
        ToolbarItem(placement: .principal) {
            Text("People")
                .foregroundStyle(.white)
                .font(.title)
                .fontWeight(.heavy)
        }
    }
        .toolbarBackground(color, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

//#Preview {
//    PeopleView()
//}

//
//  PeopleView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/17/24.
//

import SwiftUI

struct PeopleView: View {
    let contextRepresentable: any ContextRepresentable
    let color: Color
    let users: [EnrollmentType : [User]]
    
    @Binding private var navigationPath: NavigationPath
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var enrollmentTypeIsExpanded: Set<EnrollmentType>
    @State private var userIsExpanded: Set<Int>
    
    @State private var showMenu = false

    
    init(contextRep: any ContextRepresentable, navigationPath: Binding<NavigationPath>) {
        self.contextRepresentable = contextRep
        self.color = HexToColor(contextRepresentable.color) ?? .black
        self._navigationPath = navigationPath
        let set: Set = [EnrollmentType.TaEnrollment, EnrollmentType.TeacherEnrollment]
        _enrollmentTypeIsExpanded = State(initialValue: set)
        _userIsExpanded = State(initialValue: Set())
        users = contextRepresentable.people
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
                .tint(color)
            }
    }
    
    
    @ViewBuilder
    private func buildPeopleList() -> some View {
        List {
            ForEach(EnrollmentType.allCases) { enrollmentType in
                let count = users[enrollmentType]?.count ?? 0
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
                    buildUserView(users: users[enrollmentType] ?? [])
                },
                header:
                    {
                
                    Text("\(enrollmentType.rawValue.replacingOccurrences(of: "Enrollment", with: "")) (\(count))")
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
                        Text("People")
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

//#Preview {
//    PeopleView()
//}

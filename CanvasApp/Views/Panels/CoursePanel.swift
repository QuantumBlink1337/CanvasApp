//
//  CoursePanel.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/17/24.
//

import SwiftUI

struct CoursePanel: View {
    @ObservedObject var courseWrapper: CourseWrapper
    let image_width: CGFloat = 170
    let image_height: CGFloat = 80
    let userClient: UserClient
    
    let enrollment: Enrollment?
    
    @State var color: Color
    @State var showColorPicker = false
    @State var selectedColor: Color = .blue
    
    @State var showTextbox = false
    @State var selectedNickname = ""
    
    var assignmentDates: [Assignment : String] = [ : ]

    @Binding private var navigationPath: NavigationPath
    
    init(courseWrapper: CourseWrapper, navigationPath: Binding<NavigationPath>) {
        self.courseWrapper = courseWrapper
        let initialColor = (HexToColor(courseWrapper.course.color) ?? .black)
        _color = State(initialValue: initialColor)
        _selectedColor = State(initialValue: initialColor)
        self.userClient = UserClient()
//        print(String(describing: courseWrapper.course.modules))
        self._navigationPath = navigationPath
        
        let assignments = courseWrapper.course.datedAssignments![.dueSoon] ?? []
        for assignment in assignments {
            let formattedDate = formattedDate(for: assignment.dueAt ?? Date(), format: .shortForm)
            assignmentDates.updateValue(formattedDate, forKey: assignment)
        }
        self.enrollment = MainUser.selfUser?.enrollments.first(where: {
            $0.courseID == courseWrapper.course.id &&
            $0.enrollmentType == .StudentEnrollment
        })
        
        

    }
    private func updateCourseAndUser() async {
        do {
            _ = try await userClient.updateColorInfoOfCourse(courseID: courseWrapper.course.id, hexCode: (colorToHex(selectedColor) ?? "#FFFFFF"))
            _ = try await userClient.updateNicknameOfCourse(courseID: courseWrapper.course.id, nickname: courseWrapper.course.name ?? courseWrapper.course.courseCode)
                
            
        }
        catch {
            print("Failed to fetch user or courses: \(error)")
        }
        
    }
    var body: some View {
            ZStack(alignment: .topTrailing) {
                NavigationLink(destination: CourseView(courseWrapper: courseWrapper, navigationPath: $navigationPath)) {
                    VStack(alignment: .leading) {
                            ZStack(alignment: .topLeading) {
                                buildAsyncImage(urlString: courseWrapper.course.image_download_url ?? "", imageWidth: image_width, imageHeight: image_height, color: HexToColor(courseWrapper.course.color) ?? .clear, shape: .rectangle, colorOpacity: 0.5, placeShapeOnTop: true)
                        
                                let grade = enrollment?.grade
                                if (grade != nil && grade?.currentGrade != nil && grade?.currentScore != nil) {
                                    Text("\(grade?.currentGrade ?? "X") \(grade?.currentScore?.clean ?? "0")%")
                                        .padding(4)
                                        .background {
                                        RoundedRectangle(cornerRadius: 10)
                                            .foregroundStyle(.white)
//                                            .padding(.all)
                                    }.padding(.leading, 5)
                                        .padding(.top,8.0)
                                }
                            }
                                     
                            Text(courseWrapper.course.name ?? "Missing name")
                                .font(.subheadline) // Display course name
                                .multilineTextAlignment(.leading)
                                .lineLimit(2, reservesSpace: true)
                                .padding(.leading, 1.0)
                                .foregroundStyle(color)
                            Text("Due Soon")
                                .font(.footnote)
                                .multilineTextAlignment(.leading)
                                .padding(.leading, 1.0)
                                .foregroundStyle(color)
                        let assignments = courseWrapper.course.datedAssignments?[DatePriority.dueSoon] ?? []
                        if (assignments.isEmpty) {
                            HStack {
                                Text("No assignments due!")
                                    .font(.footnote)
                                    .fontWeight(.thin)
                                    .lineLimit(2, reservesSpace: true)
                            }
                        }
                        
                        ForEach(assignments, id: \.id) { assignment in
                            HStack {
                                Text(assignment.title)
                                    .font(.footnote)
                                    .fontWeight(.light)
                                    .lineLimit(2, reservesSpace: true)
                                Spacer()
                                Text(assignmentDates[assignment] ?? "XX/XX")
                                    .font(.footnote)
                                    .fontWeight(.light)
                                    .lineLimit(2, reservesSpace: true)


                            }
                        }
                        
                        

                    }.background()

                }.buttonStyle(PlainButtonStyle()).tint(.white)
                

                Menu {
                    Button() {
                        showColorPicker = true
                    } label: {
                        HStack {
                            Text("Choose course color")
                            Image(systemName: "paintbrush.pointed.fill").padding(.top, 20.0).foregroundStyle(.white)
                        }
                    }
                    Button() {
                        showTextbox = true
                    } label: {
                        HStack {
                            Text("Choose course nickname")
                            Image(systemName: "pencil.and.scribble").padding(.top, 20.0).foregroundStyle(.white)
                        }
                    }
                    
                }
                 label: {
                    Image(systemName: "paintpalette.fill").padding(.top, 20.0).foregroundStyle(.white).rotationEffect(.degrees(90))
                 }.padding(1)
                
                if showColorPicker {
                            // Dimmed background
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    // Dismiss the color picker if the user taps outside it
                                    showColorPicker = false
                                }

                            // Modal with ColorPicker
                            VStack {

                                ColorPicker("Choose a color", selection: $selectedColor)
                                    .labelsHidden()

                                Button("Done") {
                                    showColorPicker = false
                                    courseWrapper.course.color = colorToHex(selectedColor) ?? "#FFFFFF"
                                    color = HexToColor(courseWrapper.course.color) ?? .white
                                    Task {
                                        let _: () = await updateCourseAndUser()
                                    }
                                    
                                    
                                }
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .frame(width: image_width, height: image_height+20)
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                    }
                if showTextbox {
                            // Dimmed background
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    // Dismiss the color picker if the user taps outside it
                                    showTextbox = false
                                }

                            // Modal with ColorPicker
                            VStack {

                                TextField("Choose a nickname", text: $selectedNickname)
                                    .labelsHidden()

                                Button("Done") {
                                    showTextbox = false
                                    courseWrapper.course.name = selectedNickname
                                    Task {
                                        let _: () = await updateCourseAndUser()
                                    }
                                    
                                    
                                }
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .frame(width: image_width, height: image_height+20)
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                    }

                }
            
            
    }
        
        
        
        
    }

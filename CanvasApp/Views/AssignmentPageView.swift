//
//  AssignmentPageiew.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/26/25.
//

import Foundation
import SwiftUI

struct AssignmentPageView : View {
    var courseWrapper: CourseWrapper
    var assignment : Assignment
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    let color: Color
    var loadGrades: Bool = false
    var submissionTypeString: String = ""
    
    @State private var showMenu = false
    
    @Binding private var navigationPath: NavigationPath
	
	@State private var navigateToQuizSession = false
	
	@State private var newQuizSubmission: QuizSubmission?
	
	@State private var loadingNewQuizSubmission: Bool = false
	
	@State private var isShowingAttempts: Bool = false
    
	init(courseWrapper: CourseWrapper, assignment: Assignment, navigationPath: Binding<NavigationPath>) {
        self.courseWrapper = courseWrapper
        self.assignment = assignment
        self.color = HexToColor(courseWrapper.course.color) ?? .black
        self._navigationPath = navigationPath
        loadGrades = assignment.currentSubmission?.grade != nil
        prepareSubmissionTypeString()
    }
    
    mutating func prepareSubmissionTypeString() {
        for type in assignment.submissionTypes {
            submissionTypeString.append("\(type.rawValue) ")
        }
    }
    
    @ViewBuilder
    private func buildHeader() -> some View {
        VStack(alignment: .leading) {
            Text(assignment.title)
                .font(.title)
            HStack {
                Text("\(assignment.pointsPossible?.clean ?? "0") pts")
                    .font(.subheadline)
                if loadGrades {
                    Text("Graded")
                        .font(.subheadline)
                }
                if assignment.quiz != nil {
                    Spacer()
                    Text("Allowed Attempts: \((assignment.quiz?.allowedAttempts ?? 0) == -1 ? "∞" : String(assignment.quiz?.allowedAttempts ?? 0))")
                        .font(.subheadline)

                }
 
            }
        }
        .padding(.top)
        .padding(.leading)
    }
    @ViewBuilder
    private func buildAttemptView() -> some View {
        VStack {
            if assignment.currentSubmission != nil {
                HStack {
                    Text("Attempt: \(assignment.currentSubmission?.attempt ?? 0)")
                        .font(.footnote)

                    Spacer()
                    Text(formattedDate(for: assignment.currentSubmission?.submittedAt ?? Date(), format: .mediuMFormWithTime))
                        .font(.footnote)

                }
            }
            if (loadGrades) {
                VStack {
                    HStack {
                        ZStack(alignment: .center) {
                            Circle()
                                .stroke(color, lineWidth: 5)
                                .frame(width: 50, height: 50)
                            Text(String(assignment.currentSubmission?.score?.clean ?? "0"))
                            
                        }
                        Text("Out of \(assignment.pointsPossible?.clean ?? "0")")
                        Spacer()
                    }
                    if (assignment.scoreStatistic != nil) {
                        buildScoreStatistic(for: assignment, color: color)
                    }
                }.padding(.all)
                    .border(.black, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                
                    
            }
            
        }.frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
    }
    @ViewBuilder
    private func buildDueAndSubType() -> some View {
        VStack(alignment: .leading) {
            Text("Due")
                .font(.footnote)
            if (assignment.dueAt == nil) {
                Text("No Due Date")
            }
            else {
                Text("\(formattedDate(for: assignment.dueAt ?? Date(),format: .mediuMFormWithTime))")
                    .font(.caption)
                    .fontWeight(.regular)
            }
            Text("Submission Types")
                .font(.footnote)
            Text(submissionTypeString)
                .font(.caption)
                .fontWeight(.regular)

        }
        .padding(.leading)
    }
	
	private struct QuizSessionStartButton : View {
		var buttonText: String
		var assignment: Assignment
		var quiz: Quiz
		var buttonAllowed: Bool
		var color: Color
		let assignmentClient = AssignmentClient()
		var resumeQuiz = false
		
		
		@Binding var loadingNewSubmission: Bool
		@Binding var navigateToQuiz: Bool
		@Binding var newQuizSubmission: QuizSubmission?
		
		init(assignment: Assignment, color: Color, navigateToQuiz: Binding<Bool>, newQuizSubmission: Binding<QuizSubmission?>, loadingNewSubmission: Binding<Bool>) {
			self.assignment = assignment
			self.quiz = assignment.quiz!
			self.buttonText = ""
			self.buttonAllowed = false
			self.color = color
			self._loadingNewSubmission = loadingNewSubmission
			self._navigateToQuiz = navigateToQuiz
			self._newQuizSubmission = newQuizSubmission
			
			
			if quiz.submissions.allSatisfy({
				$0.workflowState == WorkflowState.Complete
			}) {
				if quiz.allowedAttempts > quiz.submissions.count || quiz.allowedAttempts == -1{
					self.buttonAllowed = true
					self.buttonText = "Start a New Quiz Session"
					
				}
			}
			if quiz.submissions.count == 1 && quiz.submissions.first?.workflowState == WorkflowState.Untaken {
				self.buttonAllowed = true
				self.buttonText = "Resume Quiz Session"
				self.resumeQuiz = true
				
			}
		}
		
		var body : some View {
			if (buttonAllowed) {
				Button(action: {
					if (!resumeQuiz) {
						Task {
							do {
								loadingNewSubmission = true
								newQuizSubmission = try await assignmentClient.createQuizSubmission(from: assignment)
								navigateToQuiz = true
								loadingNewSubmission = false
							}
							catch {
								print("Unable to start quiz submission")
								loadingNewSubmission = false
							}
						}
					}
					else {
						newQuizSubmission = quiz.submissions.first
						navigateToQuiz = true
					}
				}, label: {
					ZStack {
						RoundedRectangle(cornerRadius: 10)
							.frame(width: 200, height: 40)
							.foregroundStyle(color)
						Text("\(buttonText)")
							.foregroundStyle(.white)
							.multilineTextAlignment(.leading)
							.lineLimit(2)
							.font(.subheadline)
							.padding(.horizontal)
							
					}
				})
			}
		}
	}
    @ViewBuilder
    private func buildQuizInformation(for assignment: Assignment) -> some View {
        let quiz = assignment.quiz!

		
        VStack {
			QuizSessionStartButton(assignment: assignment, color: color, navigateToQuiz: $navigateToQuizSession, newQuizSubmission: $newQuizSubmission, loadingNewSubmission: $loadingNewQuizSubmission)
			Button(action: {isShowingAttempts.toggle()}, label: {
				ZStack {
					RoundedRectangle(cornerRadius: 10)
						.frame(width: 200, height: 40)
						.foregroundStyle(color)
					Text("Attempts")
						.foregroundStyle(.white)
						.multilineTextAlignment(.leading)
						.lineLimit(2)
						.font(.subheadline)
						.padding(.horizontal)
					
				}
			})
			.padding(.horizontal)
        }
		.sheet(isPresented: $isShowingAttempts, content: {
			VStack {
				// Header Row
				HStack {
					Text("Attempt")
						.fontWeight(.bold)
					
					Spacer()
					Text("Score")
						.fontWeight(.bold)
				}
				.padding(.vertical, 8)
				
				let keptSubmission = quiz.submissions.max {
					a, b in a.keptScore < b.keptScore
				}
				
				
				// Data Rows
				
				ForEach(quiz.submissions, id: \.attempt) { submission in
					HStack {
						Text(String(submission.attempt ?? 0))
						if submission == keptSubmission {
							Text("(Kept)")
								.font(.footnote)
						}
						Spacer()
						Text(String(submission.score ?? 0.0))
					}
					.padding(.vertical, 4)
				}
				Spacer()
				Button(action: { isShowingAttempts.toggle()}, label: {
					ZStack {
						RoundedRectangle(cornerRadius: 10)
							.frame(width: 200, height: 40)
							.foregroundStyle(color)
						Text("Dismiss")
							.foregroundStyle(.white)
							.multilineTextAlignment(.leading)
							.lineLimit(2)
							.font(.subheadline)
							.padding(.horizontal)
						
					}
				})
				
			}
			.padding(.horizontal)

		})
		
    }
        
    var body: some View {
		VStack {
			if loadingNewQuizSubmission {
				ProgressView()
			}
			else {
				VStack {
					HStack {
						buildHeader()
						Spacer()
					}
					Divider()
					buildAttemptView()
						.padding(.top, 10)
						.padding(.leading, 10)
						.padding(.trailing, 10)
					Divider()
					HStack {
						buildDueAndSubType()
							.padding(.top, 20)
						Spacer()
					}
					
					Divider()
					preparePageDisplay(page: assignment)
						.padding(.top)
						.padding(.horizontal)
					Divider()
					if (assignment.quizID != nil) {
						buildQuizInformation(for: assignment)
							.padding(.top)
					}
					
				}

			}
		}
		
		
		.navigationDestination(isPresented: $navigateToQuizSession) {
			QuizQuestionView(courseWrapper: courseWrapper, quiz: assignment.quiz!, quizSubmission: (newQuizSubmission ?? assignment.quiz?.submissions.first)!)
		}
        .overlay {
            if showMenu {
                SideMenuView(isPresented: $showMenu, navigationPath: $navigationPath)
                    .zIndex(1) // Make sure it overlays above the content
                    .transition(.move(edge: .leading))
                    .frame(maxHeight: .infinity) // Full screen height
                    .ignoresSafeArea(edges: [.trailing])
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
                        Text("Assignment Details")
                            .foregroundStyle(.white)
                            .font(.title)
                            .fontWeight(.heavy)
                    }
                    else {
                        Color.clear.frame(height: 30)

                    }
                }
        }
        .toolbarBackground(color, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

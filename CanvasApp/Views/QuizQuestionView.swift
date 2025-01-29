//
//  QuizQuestionView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/26/25.
//

import SwiftUI

struct QuizQuestionView: View {
	
	var courseWrapper: CourseWrapper
	var assignment: Assignment
	var quizSubmission: QuizSubmission
	var quizQuestions: [QuizSubmissionQuestion]
	var quiz: Quiz
	var color: Color
	
	// directed to managing the toolbar and back button
	@State private var showMenu = false
	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
	@Binding private var navigationPath: NavigationPath



	
	init(courseWrapper: CourseWrapper, assignment: Assignment, quizSubmission: QuizSubmission, quizQuestions: [QuizSubmissionQuestion], navigationPath: Binding<NavigationPath>) {
		self.courseWrapper = courseWrapper
		self.assignment = assignment
		self.quizSubmission = quizSubmission
		self.quizQuestions = quizQuestions
		self.quiz = assignment.quiz!
		self.color = HexToColor(courseWrapper.course.color) ?? .primary
		self._navigationPath = navigationPath
	}
	
	
	@ViewBuilder
	func buildQuestionList() -> some View {
		List(quizQuestions) { question in
			Text("Question ID: \(question.id)")
		}
	}
	
	
	
	
    var body: some View {
		VStack {
			Spacer()
			buildQuestionList()
			Spacer()

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
					Text("\(assignment.title)")
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



//
//  QuizQuestionView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/26/25.
//

import SwiftUI
import Combine


		
struct UserAnswer: Identifiable, Equatable {
	let id: Int  // Corresponds to QuizSubmissionQuestion.id
	var text: String  // For essay, short answer, etc.
	var selectedOptionIDs: Set<Int>  // Supports multiple answers
	var fileURL: URL?  // For file uploads
	
	var attributedText: AttributedString {
		if !text.isEmpty {
			return HTMLRenderer.makeAttributedString(from: text)
		} else {
			return AttributedString("")
		}
	}
	
	init(id: Int, text: String = "", selectedOptionIDs: Set<Int> = [], fileURL: URL? = nil) {
		self.id = id
		self.text = text
		self.selectedOptionIDs = selectedOptionIDs
		self.fileURL = fileURL
	}
	
	mutating func toggleSelection(for optionID: Int) {
		if selectedOptionIDs.contains(optionID) {
			selectedOptionIDs.remove(optionID)
		} else {
			selectedOptionIDs.insert(optionID)
		}
	}
}


struct QuizQuestionView: View {
	
	var courseWrapper: CourseWrapper
	var assignment: Assignment
	var quizSubmission: QuizSubmission?
	var quizQuestions: [QuizSubmissionQuestion]
	var quiz: Quiz
	var color: Color
	
	// directed to managing the toolbar and back button
	@State private var showMenu = false
	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
	@Binding private var navigationPath: NavigationPath
	
	@State private var userAnswers: [Int: UserAnswer] = [:]



	
	init(courseWrapper: CourseWrapper, assignment: Assignment, quizSubmission: QuizSubmission?, quizQuestions: [QuizSubmissionQuestion], navigationPath: Binding<NavigationPath>) {
		self.courseWrapper = courseWrapper
		self.assignment = assignment
		self.quizSubmission = quizSubmission
		self.quizQuestions = quizQuestions
		self.quiz = assignment.quiz!
		self.color = HexToColor(courseWrapper.course.color) ?? .primary
		self._navigationPath = navigationPath
		
		var initialUserAnswers: [Int : UserAnswer] = [:]
		for question in quizQuestions {
			initialUserAnswers[question.id] = UserAnswer(id: question.id)
		}
		_userAnswers = State(initialValue: initialUserAnswers)
	
	}
	private func binding(for questionID: Int) -> Binding<UserAnswer> {
		Binding<UserAnswer>(
			get: { self.userAnswers[questionID]! },
			set: { self.userAnswers[questionID] = $0 }
		)
	}

	
	
	
	@ViewBuilder
	func buildQuestionList() -> some View {
		List(quizQuestions) { question in
			VStack(alignment: .leading) {
				HStack {
					Text("\(question.questionName)")
						.font(.title2)
						.bold()
						.foregroundStyle(color)
					Spacer()
					VStack {
						Image(systemName: "flag")
							.foregroundStyle(color)
					}.contentShape(Circle())
						.onTapGesture {
							print("Flagged")
						}
					
						
				}
				Text("\(question.attributedText)")
					.font(.body)
				Divider()
				SingularQuestionView(question: question, userAnswer: binding(for: question.id), color: color)
			}
			.overlay {
				RoundedRectangle(cornerRadius: 10)
					.inset(by: -6)
					.strokeBorder(color, lineWidth: 2)

					
			}
			.frame(width: 340)
//			Divider()
//				.padding(.all, -5)
		}
		.scrollContentBackground(.hidden)
	}
	@ViewBuilder
	func buildQuizHeader() -> some View {
		HStack {
			Text("Worth: ")
			Text("\(assignment.pointsPossible?.clean ?? "0")")
				.foregroundStyle(.white)
				.background {
					RoundedRectangle(cornerRadius: 4)
						.inset(by: -4)
						.foregroundStyle(color)
				}
			Spacer()
			Text("Left: ")
			Text("X/\(quizQuestions.count)")
				.foregroundStyle(.white)
				.background {
					RoundedRectangle(cornerRadius: 4)
						.inset(by: -4)
						.foregroundStyle(color)
				}
		}
		.padding(.horizontal)
		.padding(.top)
	}
	
	
	
	
    var body: some View {
		VStack {
			buildQuizHeader()
			Divider()
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
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				if (!showMenu) {
					BackButton(binding: presentationMode, navigationPath: $navigationPath, action: {showMenu.toggle()})
						.padding(.bottom)

					
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
						.background(Color.clear) // Prevents unexpected extra height
						.padding(.bottom)
					


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


struct SingularQuestionView: View {
	
	let question: QuizSubmissionQuestion
	@Binding var userAnswer: UserAnswer
	let color: Color
	
	var body: some View {
		VStack {
			switch question.questionType {
				case .MultipleChoiceQuestion:
					MultipleChoiceQuestionView(question: question, userAnswer: $userAnswer, color: color)
				case .TrueFalseQuestion:
					MultipleChoiceQuestionView(question: question, userAnswer: $userAnswer, color: color)
				case .MultipleAnswersQuestion:
					MultipleAnswersQuestionView(question: question, userAnswer: $userAnswer, color: color)
				case .TextOnlyQuestion:
					EmptyView()
				case .ShortAnswerQuestion:
					TextQuestionView(question: question, userAnswer: $userAnswer, color: color)
				case .CalculatedQuestion:
					TextQuestionView(question: question, userAnswer: $userAnswer, color: color)
				default:
					Text("Not implemented")
			}
		}
	}
}
struct TextQuestionView: View {
	let question: QuizSubmissionQuestion
	@Binding var userAnswer: UserAnswer
	let color: Color
	var body: some View {
		VStack {
			TextField("Answer", text: $userAnswer.text)
			Text(userAnswer.text)
		}
		
	}
}
struct MultipleChoiceQuestionView: View {
	let question: QuizSubmissionQuestion
	@Binding var userAnswer: UserAnswer
	let color: Color
	
	var body: some View {
		ForEach(question.answers) { answer in
			HStack {
				
				Text(answer.text)
					.font(.subheadline)
					.bold(userAnswer.selectedOptionIDs.contains(answer.id))
					.foregroundStyle(userAnswer.selectedOptionIDs.contains(answer.id) ? color : .primary)
					.multilineTextAlignment(.leading)
					.lineLimit(min(3, answer.text.count / 16), reservesSpace: true)
				Spacer()
				Image(systemName: userAnswer.selectedOptionIDs.contains(answer.id) ? "dot.circle.fill" : "dot.circle")
					.foregroundStyle(userAnswer.selectedOptionIDs.contains(answer.id) ? color : .gray)
			}
			.contentShape(Rectangle())  // entire row is tappable
			.onTapGesture {
				userAnswer.selectedOptionIDs = [answer.id]
				userAnswer.text = ""
				userAnswer.fileURL = nil
			}
			.padding(.vertical, 1)
		}

	}
}
struct MultipleAnswersQuestionView: View {
	let question: QuizSubmissionQuestion
	@Binding var userAnswer: UserAnswer
	let color: Color
	
	var body: some View {
		ForEach(question.answers) { answer in
			HStack {
				Text(answer.text)
					.font(.subheadline)
					.bold(userAnswer.selectedOptionIDs.contains(answer.id))
					.foregroundStyle(userAnswer.selectedOptionIDs.contains(answer.id) ? color : .primary)
					.multilineTextAlignment(.leading)
					.lineLimit(min(3, answer.text.count / 16), reservesSpace: true)
				Spacer()
				if userAnswer.selectedOptionIDs.contains(answer.id) {
					Image(systemName: "checkmark.square.fill")
						.foregroundStyle(color)
				} else {
					Image(systemName: "square")
						.foregroundStyle(.gray)
				}
			}
			.contentShape(Rectangle())  // Entire row is tappable
			.onTapGesture {
				userAnswer.toggleSelection(for: answer.id)
			}
			.padding(.vertical, 1)
		}
	}
}

#Preview {
	let sampleCourse = Course(
		name: "Sample Course",
		courseCode: "SC101",
		id: 1,
		color: "#FF5733"
	)
	
	let sampleCourseWrapper = CourseWrapper(course: sampleCourse)
	
	let sampleQuiz = Quiz(
		id: 1,
		title: "Sample Quiz",
		dueAt: Date(),
		lockedAt: nil,
		allowedAttempts: 3,
		attributedText: AttributedString("This is a sample quiz.")
	)
	
	let sampleAssignment = Assignment(
		id: 1,
		title: "Test Quiz 3",
		dueAt: Date(),
		pointsPossible: 100,
		quiz: sampleQuiz
	)
	
	let sampleQuestions: [QuizSubmissionQuestion] = [
		QuizSubmissionQuestion(
			id: 1,
			quizID: 101,
			quizGroupID: nil,
			assessmentQuestionID: 1001,
			position: 1,
			questionName: "Basic Math",
			questionType: .CalculatedQuestion,
			questionText: "What is 5 + 3?",
			answers: [], // No predefined answers
			flagged: false
		),
		QuizSubmissionQuestion(
			id: 2,
			quizID: 101,
			quizGroupID: nil,
			assessmentQuestionID: 1002,
			position: 2,
			questionName: "Essay Response",
			questionType: .EssayQuestion,
			questionText: "Describe the effects of climate change.",
			answers: [], // Open-ended question
			flagged: false
		),
		QuizSubmissionQuestion(
			id: 3,
			quizID: 101,
			quizGroupID: nil,
			assessmentQuestionID: 1003,
			position: 3,
			questionName: "Upload Your Work",
			questionType: .FileUploadQuestion,
			questionText: "Please upload your research paper.",
			answers: [], // No predefined answers
			flagged: false
		),
		QuizSubmissionQuestion(
			id: 4,
			quizID: 101,
			quizGroupID: nil,
			assessmentQuestionID: 1004,
			position: 4,
			questionName: "Fill in the Blanks",
			questionType: .FillInMultipleBlanksQuestion,
			questionText: "The capital of France is ______.",
			answers: [], // No predefined answers
			flagged: false
		),
		QuizSubmissionQuestion(
			id: 5,
			quizID: 101,
			quizGroupID: nil,
			assessmentQuestionID: 1005,
			position: 5,
			questionName: "Matching Question",
			questionType: .MatchingQuestion,
			questionText: "Match the following countries with their capitals.",
			answers: [], // The app should not know correct answers
			flagged: false
		),
		QuizSubmissionQuestion(
			id: 6,
			quizID: 101,
			quizGroupID: nil,
			assessmentQuestionID: 1006,
			position: 6,
			questionName: "Multiple Answers",
			questionType: .MultipleAnswersQuestion,
			questionText: "Select all prime numbers.",
			answers: [
				Answer(id: 1, text: "2"),
				Answer(id: 2, text: "4"),
				Answer(id: 3, text: "5"),
				Answer(id: 4, text: "6")
			],
			flagged: false
		),
		QuizSubmissionQuestion(
			id: 7,
			quizID: 101,
			quizGroupID: nil,
			assessmentQuestionID: 1007,
			position: 7,
			questionName: "Multiple Choice",
			questionType: .MultipleChoiceQuestion,
			questionText: "What is the capital of Italy?",
			answers: [
				Answer(id: 1, text: "Paris"),
				Answer(id: 2, text: "Rome"),
				Answer(id: 3, text: "Berlin")
			],
			flagged: false
		),
		QuizSubmissionQuestion(
			id: 8,
			quizID: 101,
			quizGroupID: nil,
			assessmentQuestionID: 1008,
			position: 8,
			questionName: "Dropdown Selection",
			questionType: .MultipleDropdownsQuestion,
			questionText: "Select the correct answer from the dropdown.",
			answers: [
				Answer(id: 1, text: "Option A"),
				Answer(id: 2, text: "Option B")
			],
			flagged: false
		),
		QuizSubmissionQuestion(
			id: 9,
			quizID: 101,
			quizGroupID: nil,
			assessmentQuestionID: 1009,
			position: 9,
			questionName: "Numerical Answer",
			questionType: .NumericalQuestion,
			questionText: "What is the square root of 64?",
			answers: [], // The app should not know correct answers
			flagged: false
		),
		QuizSubmissionQuestion(
			id: 10,
			quizID: 101,
			quizGroupID: nil,
			assessmentQuestionID: 1010,
			position: 10,
			questionName: "Short Answer",
			questionType: .ShortAnswerQuestion,
			questionText: "What is the capital of Canada?",
			answers: [], // No predefined answers
			flagged: false
		),
		QuizSubmissionQuestion(
			id: 11,
			quizID: 101,
			quizGroupID: nil,
			assessmentQuestionID: 1011,
			position: 11,
			questionName: "Text Only",
			questionType: .TextOnlyQuestion,
			questionText: "This is an informational text with no answer.",
			answers: [], // No predefined answers
			flagged: false
		),
		QuizSubmissionQuestion(
			id: 12,
			quizID: 101,
			quizGroupID: nil,
			assessmentQuestionID: 1012,
			position: 12,
			questionName: "True or False",
			questionType: .TrueFalseQuestion,
			questionText: "The Earth is flat.",
			answers: [
				Answer(id: 1, text: "True"),
				Answer(id: 2, text: "False")
			],
			flagged: false
		)
	]

	
	let sampleQuizSubmission = QuizSubmission(
		id: 1,
		userID: 1,
		assignableID: sampleQuiz.id,
		score: nil,
		attempt: 1,
		workflowState: .Untaken
	)
	
	return NavigationStack {
		QuizQuestionView(
			courseWrapper: sampleCourseWrapper,
			assignment: sampleAssignment,
			quizSubmission: sampleQuizSubmission,
			quizQuestions: sampleQuestions,
			navigationPath: .constant(NavigationPath())
		)
	}
}


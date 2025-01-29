//
//  QuizQuestionView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 1/26/25.
//

import SwiftUI

struct QuizQuestionView: View {
	
	var courseWrapper: CourseWrapper
	var quiz: Quiz
	var quizSubmission: QuizSubmission
	var quizQuestions: [QuizSubmissionQuestion]
	
    var body: some View {
		Text("\(quizQuestions.count)")
    }
}



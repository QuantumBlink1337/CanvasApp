//
//  PageView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/30/24.
//

import SwiftUI
import UIKit




struct PageView: View {
    var page: Page
    var body: some View {
        HTMLTextView(htmlContent: page.body)
    }
}
#Preview {
    PageView(page: Page(id: 10, title: "Test", body: """
<h2 style="text-align: center;">Algorithm Design and Programming I</h2>
<h4 style="text-align: center;">CS1050/CS1050H</h4>
<p style="text-align: center;">
    <a title="TA/PLA Office Hours" href="https://umsystem.instructure.com/courses/253049/pages/ta-slash-pla-office-hours">
        TA/PLA Office Hours
    </a>
</p>
<p style="text-align: left;">
    Welcome! This course provides experience in developing algorithms, as well as designing and implementing programs using the C programming language.
</p>
<p style="text-align: left;">
    <strong>Lecture</strong>: The class meets Tuesdays and Thursdays from 9:30 AM - 10:45 AM.
</p>
"""))
}

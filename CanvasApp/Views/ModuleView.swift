//
//  ModuleView.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/13/24.
//

import Foundation
import SwiftUI

struct ModuleView: View {
    var courseWrapper: CourseWrapper
    
    let iconTypeLookup: [ModuleItemType : String] = [ModuleItemType.assignment : "pencil.and.list.clipboard.rtl", ModuleItemType.discussion : "person.wave.2.fill", ModuleItemType.externalTool : "book.and.wrench.fill", ModuleItemType.externalURL : "globe", ModuleItemType.file : "folder.fill", ModuleItemType.page : "book.pages.fill", ModuleItemType.subheader : "list.dash.header.rectangle", ModuleItemType.quiz : "list.bullet.rectangle.portrait.fill"]
    
    @State private var isExpanded: Set<String>
    init(courseWrapper: CourseWrapper) {
        self.courseWrapper = courseWrapper
        _isExpanded = State(initialValue: Set(courseWrapper.course.modules.map{$0.name}))
    }
    var body: some View {
            List(courseWrapper.course.modules) { module in
                Section(isExpanded: Binding<Bool> (
                    get: {
                        return isExpanded.contains(module.name)
                    },
                    set: { isExpanding in
                        if (isExpanding) {
                            isExpanded.insert(module.name)
                        }
                        else {
                            isExpanded.remove(module.name)
                        }
                    }
                ),

                        content: {
                            ForEach(module.items!, id: \.id) { moduleItem in
                            HStack {
                                Image(systemName: iconTypeLookup[ModuleItemType(rawValue: moduleItem.type)!] ?? "questionmark.app.dashed")
                                    .frame(width: 20, height: 20)
                                Text(moduleItem.title)
                                    .padding(.leading, 15.0)

                            }
                        }

                },
                        header: {
                            Text(module.name)
                        }
                )
            }
            .listStyle(.sidebar)
            
            
        
    }
}

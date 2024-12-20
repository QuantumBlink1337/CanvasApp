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
        
    @State private var moduleSectionIsExpanded: Set<Int>
    @State private var moduleItemSectionIsExpanded: Set<Int>
    
    @State private var selectedAssignment: Assignment? = nil
    @State private var loadAssignmentPage: Bool = false
    @State private var showMenu = false
    
    @State private var selectedPage: Page? = nil
    @State private var loadPage: Bool = false

    

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    let color: Color
    @Binding private var navigationPath: NavigationPath
    init(courseWrapper: CourseWrapper, navigationPath: Binding<NavigationPath>) {
        self.courseWrapper = courseWrapper
        self.color = HexToColor(courseWrapper.course.color) ?? .black
        self._navigationPath = navigationPath
        _moduleSectionIsExpanded = State(initialValue: Set())
        _moduleItemSectionIsExpanded = State(initialValue: Set())
        
    }
    private func buildModuleItems(module: Module) -> some View {
        ForEach(module.items!) { item in
                DisclosureGroup(isExpanded: Binding<Bool> (
                    get: {
                        return moduleItemSectionIsExpanded.contains(item.id)
                    },
                    set: { isExpanding in
                        if (isExpanding) {
                            moduleItemSectionIsExpanded.insert(item.id)
                        }
                        else {
                            moduleItemSectionIsExpanded.remove(item.id)
                        }
                    }
                ),
                content: {
                    if item.linkedPage != nil {
                        preparePageDisplay(page: item.linkedPage!)
                    }
//                    preparePageDisplay(page: item)
                },
                label: {
                    let icon = iconTypeLookup[item.type]
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: icon!)
                                .frame(width: 30, height: 30)
                            Text("\(item.title)")
                            if (item.linkedAssignment != nil) {
                                Spacer()
                                Text("Points: \(item.linkedAssignment?.pointsPossible?.clean ?? "0")")
                                    .font(.footnote)
                            }
                        }
                        if (item.linkedAssignment != nil) {
                            Text("Due on \(formattedDate(for: item.linkedAssignment?.dueAt ?? Date(), format: formatDate.shortForm))")
                                .font(.footnote)
                                .padding(.leading, 32)
                        }
                    }
                    
                    
                }
                )
                .simultaneousGesture(LongPressGesture().onEnded {_ in
                    
                    if item.linkedAssignment != nil {
                        selectedAssignment = item.linkedAssignment!
                        loadAssignmentPage = true
                    }
                    else if item.linkedPage != nil {
                        selectedPage = item.linkedPage!
                        loadPage = true
                    }
                })
                .tint(HexToColor(courseWrapper.course.color))
            }
    }

    
    @ViewBuilder
    private func buildModuleSectionList() -> some View {
        List {
            ForEach(courseWrapper.course.modules) { module in
                Section(isExpanded: Binding<Bool> (
                    get: {
                        return moduleSectionIsExpanded.contains(module.id)
                    },
                    set: { isExpanding in
                        if (isExpanding) {
                            moduleSectionIsExpanded.insert(module.id)
                        }
                        else {
                            moduleSectionIsExpanded.remove(module.id)
                        }
                    }
                ),
                    
                content: {
                    buildModuleItems(module: module)
                },
                header:
                    {
                    Text("\(module.name)")
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
            buildModuleSectionList()
        }
        
        .navigationDestination(isPresented: $loadAssignmentPage, destination: {
            if (selectedAssignment != nil) {
                AssignmentPageView(courseWrapper: courseWrapper, assignment: selectedAssignment!,  navigationPath: $navigationPath)

            }
        })
        .navigationDestination(isPresented: $loadPage, destination: {
            if (selectedPage != nil) {
                PageView(courseWrapper: courseWrapper, page: selectedPage!, navigationPath: $navigationPath, textAlignment: .leading)

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
                        Text("Modules")
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

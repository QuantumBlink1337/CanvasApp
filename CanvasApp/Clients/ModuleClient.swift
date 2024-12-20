//
//  ModuleClient.swift
//  CanvasApp
//
//  Created by Matt Marlow on 12/5/24.
//

import Foundation



struct ModuleClient {
    
    /// - Description: Retrieves the Modules (and optionally their ModuleItems) from the given Course.
    ///   - course: The Course to retrieve Modules from.
    ///   - includeItems: Whether to retrieve each Module's ModuleItems.
    /// - Returns: An array of Modules.
    func getModules(from course: Course, includeItems: Bool = true) async throws -> [Module] {
        let courseID = course.id
        guard let url = URL(string: baseURL + "courses/"+String(courseID)+"/modules\(includeItems ? "?include[]=items" : "")") else {
            throw NetworkError.badURL
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var request = URLRequest(url: url)
        request.addValue("Bearer " + APIToken, forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
//        print(String(data: data, encoding: .utf8) ?? "No data")
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
            }
        do {
                return try decoder.decode([Module].self, from: data)
            }
     catch DecodingError.keyNotFound(let key, let context) {
        print("Decoding error: Missing key '\(key.stringValue)' in JSON: \(context.debugDescription)")
        throw NetworkError.badDecode
    } catch DecodingError.typeMismatch(let type, let context) {
        print("Decoding error: Type mismatch for type '\(type)' in JSON: \(context.debugDescription)")
        throw NetworkError.badDecode
    } catch DecodingError.valueNotFound(let type, let context) {
        print("Decoding error: Missing value for type '\(type)' in JSON: \(context.debugDescription)")
        throw NetworkError.badDecode
    } catch DecodingError.dataCorrupted(let context) {
        print("Decoding error: Corrupted data: \(context.debugDescription)")
        throw NetworkError.badDecode
    } catch {
        print("Unknown decoding error: \(error)")
        throw NetworkError.badDecode
    }
        
    }
    
    
//    func linkModuleItemsToPages(from course: Course, fromModules: [Module] = [], pageClient: PageClient = PageClient()) async throws -> [Module] {
//        var modules = fromModules.isEmpty ? course.modules : fromModules
//        
//        // Use a task group for parallel processing
//        try await withThrowingTaskGroup(of: (Int, Int, ModuleItem).self) { group in
//            for (moduleIndex, module) in modules.enumerated() {
//                guard let items = module.items else { continue }
//                
//                for (itemIndex, item) in items.enumerated() {
//                    // Skip non-page items
//                    guard item.type == .page, let pageURL = item.pageURL else { continue }
//                    
//                    // Add a task for each page retrieval
//                    group.addTask {
//                        let linkedPage = try await pageClient.retrieveIndividualPage(from: course, pageURL: pageURL)
//                        let body = linkedPage.body
//                        var updatedItem = item
//                        updatedItem.linkedPage = linkedPage
//                        updatedItem.linkedPage?.attributedText = HTMLRenderer.makeAttributedString(from: body ?? "")
//                        return (moduleIndex, itemIndex, updatedItem)
//                    }
//                }
//            }
//            
//            // Collect the results
//            for try await (moduleIndex, itemIndex, updatedItem) in group {
//                // Update the module item in-place
//                modules[moduleIndex].items?[itemIndex] = updatedItem
//            }
//        }
//        
//        return modules
//    }

    func linkModuleItemsToPages(
        from course: Course,
        fromModules: [Module] = [],
        pageClient: PageClient = PageClient()
    ) async throws -> [Module] {
        var modules = fromModules.isEmpty ? course.modules : fromModules

        // A temporary storage for updated items
        var updatedItemsByModuleIndex: [Int: [ModuleItem]] = [:]

        try await withThrowingTaskGroup(of: (Int, [ModuleItem]).self) { group in
            for (moduleIndex, module) in modules.enumerated() {
                guard let items = module.items else {
                    print("Skipping module \(module.id) as it has no items.")
                    continue
                }

                // Add a task for processing items in this module
                group.addTask {
                    var updatedItems = [ModuleItem]()
                    for item in items {
                        if item.type == .page, let pageURL = item.pageURL {
                            do {
                                // Attempt to link the page
                                var updatedItem = item
                                updatedItem.linkedPage = try await pageClient.retrieveIndividualPage(from: course, pageURL: pageURL)
                                if let body = updatedItem.linkedPage?.body {
                                    updatedItem.linkedPage?.attributedText = HTMLRenderer.makeAttributedString(from: body)
                                }
                                updatedItems.append(updatedItem)
                            } catch {
                                // Log failure but continue processing other items
                                print("Failed to link page for item \(item.id): \(error)")
                                updatedItems.append(item) // Preserve the original item
                            }
                        } else {
                            updatedItems.append(item) // Non-page items remain unchanged
                        }
                    }
                    return (moduleIndex, updatedItems)
                }
            }

            // Collect results from task group
            for try await (moduleIndex, updatedItems) in group {
                updatedItemsByModuleIndex[moduleIndex] = updatedItems
            }
        }

        // Apply updated items back to modules
        for (moduleIndex, updatedItems) in updatedItemsByModuleIndex {
            modules[moduleIndex].items = updatedItems
        }

        return modules
    }

    
}

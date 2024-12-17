//
//  ClientUtilities.swift
//  CanvasApp
//
//  Created by Matt Marlow on 11/28/24.
//

import Foundation

enum NetworkError: Error {
    case badURL
    case invalidResponse
    case badDecode
}
var APIToken: String = ""
let baseURL: String = "https://umsystem.instructure.com/api/v1/"

var localSettingsFile: URL = Foundation.URL.documentsDirectory.appendingPathComponent("/portrait.txt")


private func createFileIfNeeded() {
    let fileManager = FileManager.default
    if (!fileManager.fileExists(atPath: localSettingsFile.path())) {
        do {
            try "".write(to: localSettingsFile, atomically: true, encoding: .utf8)
        }
        catch {
            print("Failed to create file")
        }
    }
}


func retrieveAPIToken() -> Bool {
    createFileIfNeeded()
    do {
        APIToken = try String(contentsOf: localSettingsFile)
    }
    catch {
        print("Failed to open file")
    }
    return APIToken.isEmpty
}

func storeAPIToken(api: String) {
    APIToken = api
    do {
        try APIToken.write(to: localSettingsFile, atomically: true, encoding: .utf8)
    }
    catch {
        print("Failed to write API token")
    }
}

func clearFile() {
    do {
        try "".write(to: localSettingsFile, atomically: true, encoding: .utf8)
        print("File cleared successfully.")
    } catch {
        print("Failed to clear file: \(error)")
    }
}

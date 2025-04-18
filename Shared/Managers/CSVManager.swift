import Foundation
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#else
import UIKit
#endif

class CSVManager {
    static let shared = CSVManager()
    
    // UserDefaults keys
    private let goalsPathKey = "savedGoalsCSVPath"
    private let pomosPathKey = "savedPomosCSVPath"
    
    // Initialize with default paths and check for saved paths
    init() {
        print("CSVManager initialized")
        
        // Check if we have saved paths
        if let savedGoalsPath = UserDefaults.standard.string(forKey: goalsPathKey) {
            print("Found saved goals CSV path: \(savedGoalsPath)")
        }
        
        if let savedPomosPath = UserDefaults.standard.string(forKey: pomosPathKey) {
            print("Found saved pomos CSV path: \(savedPomosPath)")
        } else {
            print("No saved pomos CSV path - will prompt on first save")
        }
    }
    
    // Validate saved path exists and is accessible
    private func validateSavedPath(_ pathKey: String) -> Bool {
        guard let path = UserDefaults.standard.string(forKey: pathKey) else {
            return false
        }
        
        // Check if file exists and is accessible
        if FileManager.default.fileExists(atPath: path) {
            // Try to access the file to confirm permissions
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: path)
                print("Path is valid and accessible: \(path)")
                return true
            } catch {
                print("Path exists but is not accessible: \(path), Error: \(error)")
                return false
            }
        }
        
        print("Path does not exist: \(path)")
        return false
    }
    
    // MARK: - Platform Specific File Selection
    
    #if os(macOS)
    // macOS implementation of file selection dialog
    func promptForGoalsFile(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.message = "Please select your Goals CSV file"
            panel.prompt = "Select"
            
            // Allow CSV files
            panel.allowedContentTypes = [UTType.commaSeparatedText]
            
            // Add CSV file type if available (macOS 11+)
            if #available(macOS 11.0, *) {
                if let csvType = UTType(filenameExtension: "csv") {
                    panel.allowedContentTypes = [csvType]
                }
            }
            
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    print("User selected goals file: \(url.path)")
                    
                    // Save the selected path for future use
                    UserDefaults.standard.set(url.path, forKey: self.goalsPathKey)
                    UserDefaults.standard.synchronize()
                    
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    func promptForPomosFile(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let panel = NSSavePanel()
            panel.canCreateDirectories = true
            panel.nameFieldStringValue = "pomos_log.csv"
            panel.message = "Choose where to save your Pomodoro logs"
            panel.prompt = "Save"
            
            // Allow CSV files
            if #available(macOS 11.0, *) {
                if let csvType = UTType(filenameExtension: "csv") {
                    panel.allowedContentTypes = [csvType]
                }
            }
            
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    print("User selected pomos log file: \(url.path)")
                    
                    // Save the selected path for future use
                    UserDefaults.standard.set(url.path, forKey: self.pomosPathKey)
                    UserDefaults.standard.synchronize()
                    
                    // Create the file with headers if it doesn't exist
                    if !FileManager.default.fileExists(atPath: url.path) {
                        // Default 6-column format headers (including emoji)
                        let headers = ",\"Start\",\"End\",\"Icon\",\"Project/Area Link\",\"Total\"\n"
                        do {
                            try headers.write(toFile: url.path, atomically: true, encoding: .utf8)
                            print("Created new pomos log file with 6-column headers including emoji")
                        } catch {
                            print("Error creating pomos log file: \(error)")
                        }
                    }
                    
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    #else
    // iOS implementation using document picker
    func promptForGoalsFile(completion: @escaping (Bool) -> Void) {
        // Get the top view controller to present from
        guard let topVC = UIApplication.shared.windows.first?.rootViewController else {
            print("Cannot find top view controller to present document picker")
            completion(false)
            return
        }
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.commaSeparatedText])
        documentPicker.allowsMultipleSelection = false
        
        documentPicker.delegate = DocumentPickerDelegate.shared
        
        // Set up a completion handler
        DocumentPickerDelegate.shared.completion = { urls in
            if let url = urls.first {
                print("User selected goals file: \(url.path)")
                
                // We need to create security-scoped bookmarks for iOS
                do {
                    let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
                    UserDefaults.standard.set(bookmarkData, forKey: self.goalsPathKey + "_bookmark")
                    
                    // Also store the original URL string for reference
                    UserDefaults.standard.set(url.path, forKey: self.goalsPathKey)
                    UserDefaults.standard.synchronize()
                    
                    completion(true)
                } catch {
                    print("Error creating bookmark: \(error)")
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
        
        topVC.present(documentPicker, animated: true)
    }
    
    func promptForPomosFile(completion: @escaping (Bool) -> Void) {
        // Get the top view controller to present from
        guard let topVC = UIApplication.shared.windows.first?.rootViewController else {
            print("Cannot find top view controller to present document picker")
            completion(false)
            return
        }
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.commaSeparatedText])
        documentPicker.allowsMultipleSelection = false
        
        documentPicker.delegate = DocumentPickerDelegate.shared
        
        // Set up a completion handler
        DocumentPickerDelegate.shared.completion = { urls in
            if let url = urls.first {
                print("User selected pomos log file: \(url.path)")
                
                // We need to create security-scoped bookmarks for iOS
                do {
                    let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
                    UserDefaults.standard.set(bookmarkData, forKey: self.pomosPathKey + "_bookmark")
                    
                    // Also store the original URL string for reference
                    UserDefaults.standard.set(url.path, forKey: self.pomosPathKey)
                    UserDefaults.standard.synchronize()
                    
                    // Check if we need to create the file with headers
                    if !FileManager.default.fileExists(atPath: url.path) {
                        // Default 6-column format headers (including emoji)
                        let headers = ",\"Start\",\"End\",\"Icon\",\"Project/Area Link\",\"Total\"\n"
                        do {
                            try headers.write(toFile: url.path, atomically: true, encoding: .utf8)
                            print("Created new pomos log file with 6-column headers including emoji")
                        } catch {
                            print("Error creating pomos log file: \(error)")
                        }
                    }
                    
                    completion(true)
                } catch {
                    print("Error creating bookmark: \(error)")
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
        
        topVC.present(documentPicker, animated: true)
    }
    
    // Helper class for handling document picker delegate methods
    class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
        static let shared = DocumentPickerDelegate()
        var completion: (([URL]) -> Void)?
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            completion?(urls)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion?([])
        }
    }
    #endif
    
    // MARK: - Shared File Operations
    
    // Try to load goals from saved path or prompt user to select file
    func loadGoals(completion: @escaping ([Goal]) -> Void) {
        // Check if the saved path is valid
        if validateSavedPath(goalsPathKey), let savedPath = UserDefaults.standard.string(forKey: goalsPathKey) {
            print("Attempting to load from saved path: \(savedPath)")
            
            // Try loading from the saved path
            loadGoalsFromPath(savedPath) { success, goals in
                if success {
                    // Path still works, use the goals
                    print("Successfully loaded \(goals.count) goals from saved path")
                    completion(goals)
                } else {
                    print("Failed to load from saved path - will prompt for file selection")
                    // Saved path didn't work, prompt user to select a file
                    self.promptForGoalsFile { success in
                        if success {
                            // User selected a file, now load it
                            if let newPath = UserDefaults.standard.string(forKey: self.goalsPathKey) {
                                self.loadGoalsFromPath(newPath) { _, loadedGoals in
                                    completion(loadedGoals)
                                }
                            } else {
                                completion([])
                            }
                        } else {
                            // User cancelled file selection
                            print("User cancelled file selection")
                            completion([])
                        }
                    }
                }
            }
        } else {
            // No saved path or it's invalid, prompt user to select a file
            print("No valid saved path - prompting for file selection")
            promptForGoalsFile { success in
                if success {
                    // User selected a file, now load it
                    if let newPath = UserDefaults.standard.string(forKey: self.goalsPathKey) {
                        self.loadGoalsFromPath(newPath) { _, loadedGoals in
                            completion(loadedGoals)
                        }
                    } else {
                        completion([])
                    }
                } else {
                    // User cancelled file selection
                    print("User cancelled file selection")
                    completion([])
                }
            }
        }
    }
    
    // Load goals from a specific file path
    private func loadGoalsFromPath(_ path: String, completion: @escaping (Bool, [Goal]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Check if file exists
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: path) {
                    print("ERROR: CSV file not found at path: \(path)")
                    DispatchQueue.main.async {
                        completion(false, [])
                    }
                    return
                }
                
                // Try to read the file
                let csvContent = try String(contentsOfFile: path, encoding: .utf8)
                print("CSV content loaded - length: \(csvContent.count) characters")
                
                if csvContent.isEmpty {
                    print("WARNING: CSV file is empty")
                    DispatchQueue.main.async {
                        completion(false, [])
                    }
                    return
                }
                
                // Debug - show the first part of the content
                print("First 100 characters: \(String(csvContent.prefix(100)))")
                
                // Parse the CSV content
                let goals = self.parseGoalsFromCSV(csvContent)
                
                DispatchQueue.main.async {
                    if goals.isEmpty {
                        print("WARNING: No goals could be parsed from the CSV")
                        completion(false, [])
                    } else {
                        print("Successfully parsed \(goals.count) goals from CSV")
                        completion(true, goals)
                    }
                }
            } catch {
                print("Error loading goals CSV: \(error)")
                DispatchQueue.main.async {
                    completion(false, [])
                }
            }
        }
    }
    
    // Parse goals from CSV content
    private func parseGoalsFromCSV(_ csvContent: String) -> [Goal] {
        var goals: [Goal] = []
        
        // Split by lines
        let lines = csvContent.components(separatedBy: .newlines)
        print("CSV contains \(lines.count) lines")
        
        // Try to find header row to determine column indices
        var emojiIndex = 1    // Default expected position for emoji
        var nameIndex = 2     // Default expected position for name
        var typeIndex = 3
        var statusIndex = 4
        var priorityIndex = 5
        var contextIndex = 6
        var dueIndex = 7
        
        if lines.count > 0 {
            // Check several initial rows for headers
            for lineIndex in 0..<min(5, lines.count) {
                let headerFields = parseCSVLine(lines[lineIndex])
                print("Checking row \(lineIndex) for headers: \(headerFields)")
                
                // Try to find column indices by header names
                for (index, field) in headerFields.enumerated() {
                    let cleanField = field.trimmingCharacters(in: .whitespacesAndNewlines)
                    if cleanField == "Name" || cleanField == "name" {
                        nameIndex = index
                        print("Found 'Name' column at index \(index)")
                    } else if cleanField == "Type" || cleanField == "type" {
                        typeIndex = index
                        print("Found 'Type' column at index \(index)")
                    } else if cleanField == "Status" || cleanField == "status" {
                        statusIndex = index
                        print("Found 'Status' column at index \(index)")
                    } else if cleanField == "Priority" || cleanField == "priority" {
                        priorityIndex = index
                        print("Found 'Priority' column at index \(index)")
                    } else if cleanField == "Context" || cleanField == "context" {
                        contextIndex = index
                        print("Found 'Context' column at index \(index)")
                    } else if cleanField == "Due" || cleanField == "due" {
                        dueIndex = index
                        print("Found 'Due' column at index \(index)")
                    }
                }
                
                // If we found header matches, we can stop searching
                if headerFields.contains(where: { $0.contains("Name") || $0.contains("name") }) {
                    break
                }
            }
        }
        
        // Skip first few rows (metadata and headers)
        var dataStartRow = 1
        
        // Try to find where actual data starts by looking for the first row with content in the name column
        for i in 1..<min(15, lines.count) {
            if i < lines.count {
                let fields = parseCSVLine(lines[i])
                if fields.count > nameIndex && !fields[nameIndex].isEmpty &&
                   fields[nameIndex] != "Name" && fields[nameIndex] != "name" {
                    // Found a row with data in the name column
                    dataStartRow = i
                    print("Found first data row at index \(i)")
                    break
                }
            }
        }
        
        // Process data rows
        for i in dataStartRow..<lines.count {
            let line = lines[i]
            if line.isEmpty { continue }
            
            let fields = parseCSVLine(line)
            
            // Make sure we have enough fields
            if fields.count > max(nameIndex, typeIndex, statusIndex, priorityIndex, contextIndex, dueIndex) {
                let name = fields[nameIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip empty names and header rows
                if !name.isEmpty && name != "Name" && name != "name" {
                    // Get emoji from column 1 (second column, index 1)
                    let emoji = fields.count > emojiIndex ? fields[emojiIndex].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                    let type = fields[typeIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                    let status = fields[statusIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                    let priorityString = fields[priorityIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                    let context = fields[contextIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                    let due = fields[dueIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Parse priority as Double
                    let priority = Double(priorityString) ?? 0.0
                    
                    let goal = Goal(emoji: emoji, name: name, type: type, status: status, priority: priority, context: context, due: due)
                    goals.append(goal)
                    
                    print("Added goal: \(emoji) \(name)")
                }
            }
        }
        
        print("Total goals found: \(goals.count)")
        return goals
    }
    
    // Helper to properly parse CSV lines respecting quoted fields
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        
        for character in line {
            if character == "\"" {
                inQuotes.toggle()
            } else if character == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(character)
            }
        }
        
        // Add the last field
        fields.append(currentField)
        
        return fields
    }
    
    // Save a completed pomodoro to the CSV file
    func savePomodoro(goal: Goal, startTime: Date, endTime: Date, durationSeconds: Int) {
        // Check if we have a valid saved path
        let isValidPath = validateSavedPath(pomosPathKey)
        
        if isValidPath, let pomosPath = UserDefaults.standard.string(forKey: pomosPathKey) {
            appendPomodoroToPath(pomosPath, goal: goal, startTime: startTime, endTime: endTime, durationSeconds: durationSeconds)
        } else {
            // No valid saved path, prompt user to select a file
            promptForPomosFile { success in
                if success, let newPath = UserDefaults.standard.string(forKey: self.pomosPathKey) {
                    self.appendPomodoroToPath(newPath, goal: goal, startTime: startTime, endTime: endTime, durationSeconds: durationSeconds)
                }
            }
        }
    }
    
    // Detect file format (column count and structure)
    private func detectFileFormat(path: String) -> (columnCount: Int, hasEmptyFirstColumn: Bool, hasEmojiColumn: Bool, dateFormat: String)? {
        do {
            // Read the first line of the file
            let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
            let data = fileHandle.readData(ofLength: 1000)
            fileHandle.closeFile()
            
            // Check if we got any data
            if data.isEmpty {
                return nil
            }
            
            // Convert to string and get the first line
            guard let content = String(data: data, encoding: .utf8) else { return nil }
            let lines = content.components(separatedBy: .newlines)
            guard let headerLine = lines.first, !headerLine.isEmpty else { return nil }
            
            // Parse the header line
            let headerFields = parseCSVLine(headerLine)
            let columnCount = headerFields.count
            
            // Check if first column is empty
            let hasEmptyFirstColumn = headerFields.first?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false
            
            // Check if there's an icon/emoji column
            let hasEmojiColumn = headerFields.contains { field in
                let cleanField = field.trimmingCharacters(in: .whitespacesAndNewlines)
                return cleanField == "Icon" || cleanField == "Emoji" || cleanField == "icon" || cleanField == "emoji"
            }
            
            // Try to detect date format from second line if available
            var dateFormat = "yyyy-MM-dd HH:mm:ss" // Default format
            if lines.count > 1 {
                let dataLine = lines[1]
                let fields = parseCSVLine(dataLine)
                
                // Get the date field (typically second column)
                if fields.count > 1 {
                    let dateField = fields[1].replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !dateField.isEmpty {
                        // Attempt to detect format - this is simplified and might need enhancement
                        if dateField.contains("/") {
                            // Likely MM/dd/yyyy format
                            dateFormat = "MM/dd/yyyy HH:mm:ss"
                        }
                    }
                }
            }
            
            print("Detected file format - Columns: \(columnCount), Empty first column: \(hasEmptyFirstColumn), Has emoji column: \(hasEmojiColumn), Date format: \(dateFormat)")
            return (columnCount, hasEmptyFirstColumn, hasEmojiColumn, dateFormat)
        } catch {
            print("Error detecting file format: \(error)")
            return nil
        }
    }
    
    // Append pomodoro to a specific file path
    private func appendPomodoroToPath(_ path: String, goal: Goal, startTime: Date, endTime: Date, durationSeconds: Int) {
        print("Attempting to save Pomodoro to: \(path)")
        
        do {
            // Check if file exists
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: path) {
                // Create the file with 6-column headers (matching expected format with emoji)
                let headers = ",\"Start\",\"End\",\"Icon\",\"Project/Area Link\",\"Total\"\n"
                try headers.write(toFile: path, atomically: true, encoding: .utf8)
                print("Created new pomos log file with 6-column headers including emoji")
            }
            
            // Detect the file format
            let fileFormat = detectFileFormat(path: path) ?? (columnCount: 6, hasEmptyFirstColumn: true, hasEmojiColumn: true, dateFormat: "yyyy-MM-dd HH:mm:ss")
            
            // Format the dates according to detected format
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = fileFormat.dateFormat
            let startDateString = dateFormatter.string(from: startTime)
            let endDateString = dateFormatter.string(from: endTime)
            
            // Create CSV line for the pomodoro
            var pomoLine: String
            if fileFormat.columnCount >= 6 && fileFormat.hasEmptyFirstColumn && fileFormat.hasEmojiColumn {
                // 6-column format with empty first column and emoji (matching our new format)
                pomoLine = ",\"\(startDateString)\",\"\(endDateString)\",\"\(goal.emoji)\",\"\(goal.name)\",\"\(durationSeconds)\"\n"
            } else if fileFormat.columnCount == 5 && fileFormat.hasEmptyFirstColumn {
                // 5-column format with empty first column (older format without emoji)
                pomoLine = ",\"\(startDateString)\",\"\(endDateString)\",\"\(goal.name)\",\"\(durationSeconds)\"\n"
            } else {
                // 4-column format (simplest default)
                pomoLine = "\"\(startDateString)\",\"\(endDateString)\",\"\(goal.name)\",\"\(durationSeconds)\"\n"
            }
            
            // Read the file to check if it ends with a newline
            let currentContent = try String(contentsOfFile: path, encoding: .utf8)
            let endsWithNewline = currentContent.hasSuffix("\n")
            
            // Get the file handle for writing
            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
            fileHandle.seekToEndOfFile()
            
            // If the file doesn't end with a newline, add one first
            if !endsWithNewline && !currentContent.isEmpty {
                let newlineData = "\n".data(using: .utf8)!
                fileHandle.write(newlineData)
            }
            
            // Add the new pomodoro
            if let data = pomoLine.data(using: .utf8) {
                fileHandle.write(data)
                print("Successfully appended Pomodoro for \(goal.emoji) \(goal.name) to \(path) using \(fileFormat.columnCount)-column format")
            }
            
            fileHandle.closeFile()
        } catch {
            print("Error saving Pomodoro: \(error)")
            
            // If there was an error, try to prompt for a new location
            #if os(macOS)
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Error Saving Pomodoro"
                alert.informativeText = "Could not save to the pomodoro log file. Would you like to select a different location?"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Select New Location")
                alert.addButton(withTitle: "Cancel")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    // User wants to try a different location
                    self.promptForPomosFile { success in
                        if success, let newPath = UserDefaults.standard.string(forKey: self.pomosPathKey) {
                            self.appendPomodoroToPath(newPath, goal: goal, startTime: startTime, endTime: endTime, durationSeconds: durationSeconds)
                        }
                    }
                }
            }
            #else
            // For iOS, we'll need a different approach to show an alert
            DispatchQueue.main.async {
                // Get the top view controller to present an alert
                if let topVC = UIApplication.shared.windows.first?.rootViewController {
                    let alert = UIAlertController(
                        title: "Error Saving Pomodoro",
                        message: "Could not save to the pomodoro log file. Would you like to select a different location?",
                        preferredStyle: .alert
                    )
                    
                    alert.addAction(UIAlertAction(title: "Select New Location", style: .default) { _ in
                        self.promptForPomosFile { success in
                            if success, let newPath = UserDefaults.standard.string(forKey: self.pomosPathKey) {
                                self.appendPomodoroToPath(newPath, goal: goal, startTime: startTime, endTime: endTime, durationSeconds: durationSeconds)
                            }
                        }
                    })
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    
                    topVC.present(alert, animated: true)
                }
            }
            #endif
        }
    }
}
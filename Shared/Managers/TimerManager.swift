import Foundation
import SwiftUI
import Combine
import UserNotifications

class TimerManager: ObservableObject {
    // MARK: - Published Properties
    @Published var pomodoroLength: Int = 25
    @Published var remainingTime: Int
    @Published var isTimerRunning = false
    @Published var selectedGoalIndex = 0
    @Published var goals: [Goal] = []
    
    // MARK: - Private Properties
    private var startTime: Date?
    private var timer: AnyCancellable?
    
    #if os(iOS)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    #endif
    
    var timeString: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Initialization
    init() {
        self.remainingTime = pomodoroLength * 60
        loadGoals()
    }
    
    // MARK: - Timer Control Methods
    func toggleTimer() {
        isTimerRunning.toggle()
        
        if isTimerRunning {
            // Starting the timer
            startTimer()
            if startTime == nil {
                startTime = Date()
            }
            
            #if os(iOS)
            // Request background execution permission
            registerBackgroundTask()
            
            // Start Live Activity if available
            if #available(iOS 16.1, *), selectedGoalIndex < goals.count {
                LiveActivityManager.shared.startLiveActivity(
                    goal: goals[selectedGoalIndex],
                    pomodoroLength: pomodoroLength,
                    remainingTime: remainingTime
                )
            }
            #endif
        } else {
            // Pausing the timer
            timer?.cancel()
            
            #if os(iOS)
            // Update Live Activity with paused state
            if #available(iOS 16.1, *) {
                LiveActivityManager.shared.updateLiveActivity(
                    remainingTime: remainingTime,
                    isRunning: false
                )
            }
            
            endBackgroundTask()
            #endif
        }
    }
    
    func startTimer() {
        timer?.cancel()
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if self.remainingTime > 0 {
                    self.remainingTime -= 1
                    
                    #if os(iOS)
                    // Update Live Activity with new remaining time
                    if #available(iOS 16.1, *), self.isTimerRunning {
                        LiveActivityManager.shared.updateLiveActivity(
                            remainingTime: self.remainingTime,
                            isRunning: true
                        )
                    }
                    #endif
                } else {
                    self.completePomodoro()
                }
            }
    }
    
    func resetTimer() {
        isTimerRunning = false
        timer?.cancel()
        remainingTime = pomodoroLength * 60
        startTime = nil
        
        #if os(iOS)
        // End Live Activity if active
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.endLiveActivity()
        }
        
        endBackgroundTask()
        #endif
    }
    
    func finishPomodoroEarly() {
        // Calculate actual duration
        guard let startTime = startTime else { return }
        let actualDuration = Int(Date().timeIntervalSince(startTime))
        
        // Save the actual duration (minimum 1 minute to count)
        if actualDuration >= 60 {
            let endTime = Date()
            guard selectedGoalIndex < goals.count else { return }
            
            let selectedGoal = goals[selectedGoalIndex]
            savePomodoro(goal: selectedGoal, startTime: startTime, endTime: endTime, durationSeconds: actualDuration)
            
            // Send notification
            sendNotification(title: "Pomodoro Completed Early", 
                             body: "You completed a \(actualDuration/60) minute pomodoro for: \(selectedGoal.emoji) \(selectedGoal.name)")
        }
        
        #if os(iOS)
        // End Live Activity if active
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.endLiveActivity()
        }
        #endif
        
        // Reset timer
        resetTimer()
    }
    
    func completePomodoro() {
        isTimerRunning = false
        timer?.cancel()
        
        // Send notification
        sendNotification()
        
        // Save the completed pomodoro
        savePomodoro()
        
        #if os(iOS)
        // End Live Activity if active
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.endLiveActivity()
        }
        
        endBackgroundTask()
        #endif
        
        // Reset the timer
        resetTimer()
    }
    
    // MARK: - CSV Integration
    func loadGoals() {
        CSVManager.shared.loadGoals { [weak self] loadedGoals in
            DispatchQueue.main.async {
                if loadedGoals.isEmpty {
                    // Provide default goals so app is still usable
                    self?.goals = [
                        Goal(emoji: "📋", name: "Default Goal 1", type: "Project", status: "Active", priority: 1.0, context: "General", due: ""),
                        Goal(emoji: "🎯", name: "Default Goal 2", type: "Project", status: "Active", priority: 1.0, context: "General", due: "")
                    ]
                } else {
                    self?.goals = loadedGoals
                }
                
                if !(self?.goals.isEmpty ?? true) {
                    self?.selectedGoalIndex = 0
                }
            }
        }
    }
    
    func savePomodoro() {
        guard selectedGoalIndex < goals.count else { return }
        guard let startTime = startTime else { return }
        
        let selectedGoal = goals[selectedGoalIndex]
        let endTime = Date()
        let durationSeconds = pomodoroLength * 60
        
        savePomodoro(goal: selectedGoal, startTime: startTime, endTime: endTime, durationSeconds: durationSeconds)
    }
    
    func savePomodoro(goal: Goal, startTime: Date, endTime: Date, durationSeconds: Int) {
        CSVManager.shared.savePomodoro(
            goal: goal,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds
        )
    }
    
    // MARK: - Notifications
    func sendNotification(title: String = "Pomodoro Completed!", 
                          body: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        
        if let body = body {
            content.body = body
        } else if selectedGoalIndex < goals.count {
            content.body = "Great job! You've completed a \(pomodoroLength) minute pomodoro for: \(goals[selectedGoalIndex].emoji) \(goals[selectedGoalIndex].name)"
        } else {
            content.body = "Great job! You've completed a \(pomodoroLength) minute pomodoro!"
        }
        
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Background Task Management (iOS Only)
    #if os(iOS)
    func registerBackgroundTask() {
        // End any existing tasks first
        endBackgroundTask()
        
        // Start a new background task
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    #endif
    
    // MARK: - Utilities
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }
}
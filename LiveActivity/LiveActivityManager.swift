import Foundation
import SwiftUI

#if os(iOS)
import ActivityKit

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var activity: Activity<PomodoroAttributes>?
    
    // Start a new Live Activity for the Pomodoro timer
    func startLiveActivity(goal: Goal, pomodoroLength: Int, remainingTime: Int) {
        // Only available on iOS 16.1+
        guard #available(iOS 16.1, *) else {
            print("Live Activities not available on this device")
            return
        }
        
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Activities not enabled for this app")
            return
        }
        
        // Calculate the end time
        let endTime = Date().addingTimeInterval(TimeInterval(remainingTime))
        
        // Create the attributes
        let attributes = PomodoroAttributes(
            startTime: Date(),
            timerName: "Pomodoro Timer"
        )
        
        // Create the initial content state
        let initialContentState = PomodoroAttributes.ContentState(
            remainingTime: remainingTime,
            pomodoroLength: pomodoroLength,
            goalName: goal.name,
            goalEmoji: goal.emoji,
            isRunning: true,
            endTime: endTime
        )
        
        // Start the Live Activity
        do {
            activity = try Activity.request(
                attributes: attributes,
                contentState: initialContentState,
                pushType: nil
            )
            print("Started Live Activity with ID: \(activity?.id ?? "unknown")")
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }
    
    // Update the Live Activity with new information
    func updateLiveActivity(remainingTime: Int, isRunning: Bool) {
        guard let activity = activity else {
            print("No active Live Activity to update")
            return
        }
        
        // Only available on iOS 16.1+
        guard #available(iOS 16.1, *) else { return }
        
        // Calculate the new end time based on whether the timer is running
        let endTime: Date
        if isRunning {
            endTime = Date().addingTimeInterval(TimeInterval(remainingTime))
        } else {
            // If paused, we'll use a placeholder future time
            endTime = Date().addingTimeInterval(TimeInterval(24 * 60 * 60)) // 24 hours in the future
        }
        
        // Update the content state
        let updatedContentState = PomodoroAttributes.ContentState(
            remainingTime: remainingTime,
            pomodoroLength: activity.content.state.pomodoroLength,
            goalName: activity.content.state.goalName,
            goalEmoji: activity.content.state.goalEmoji,
            isRunning: isRunning,
            endTime: endTime
        )
        
        // Apply the update
        Task {
            await activity.update(using: updatedContentState)
        }
    }
    
    // End the Live Activity
    func endLiveActivity() {
        guard let activity = activity else {
            print("No active Live Activity to end")
            return
        }
        
        // Only available on iOS 16.1+
        guard #available(iOS 16.1, *) else { return }
        
        // End the activity
        Task {
            await activity.end(dismissalPolicy: .immediate)
            self.activity = nil
        }
    }
}
#endif
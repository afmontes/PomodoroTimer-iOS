import Foundation
import ActivityKit

// The attributes for our Live Activity
struct PomodoroAttributes: ActivityAttributes {
    // The static data that will be shown in the Live Activity
    public struct ContentState: Codable, Hashable {
        // Remaining seconds in the timer
        var remainingTime: Int
        // The total length of the pomodoro in minutes
        var pomodoroLength: Int
        // The name of the goal
        var goalName: String
        // The emoji for the goal
        var goalEmoji: String
        // Whether the timer is running or paused
        var isRunning: Bool
        // The end time (used to calculate time remaining)
        var endTime: Date
    }
    
    // The fixed attributes that remain the same while the Live Activity is running
    var startTime: Date
    var timerName: String
}
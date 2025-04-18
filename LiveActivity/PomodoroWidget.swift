import SwiftUI
import WidgetKit

#if os(iOS)
import ActivityKit

@available(iOS 16.1, *)
struct PomodoroWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroAttributes.self) { context in
            // Lock screen/banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Dynamic Island expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Text(context.attributes.startTime, style: .time)
                            .font(.caption2)
                        Text("-")
                        Text(context.state.endTime, style: .time)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    HStack {
                        Text(context.state.isRunning ? "Running" : "Paused")
                            .font(.caption)
                            .foregroundColor(context.state.isRunning ? .green : .orange)
                        
                        Image(systemName: context.state.isRunning ? "play.circle.fill" : "pause.circle.fill")
                            .foregroundColor(context.state.isRunning ? .green : .orange)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    HStack {
                        Text(context.state.goalEmoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text(context.state.goalName)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text(timeString(from: context.state.remainingTime))
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: Double(context.state.remainingTime), total: Double(context.state.pomodoroLength * 60))
                        .progressViewStyle(LinearProgressViewStyle(tint: context.state.isRunning ? .red : .orange))
                        .padding(.horizontal)
                }
            } compactLeading: {
                // Dynamic Island compact leading UI
                HStack {
                    Text(context.state.goalEmoji)
                    Text(timeString(from: context.state.remainingTime))
                        .monospacedDigit()
                        .font(.caption)
                }
            } compactTrailing: {
                // Dynamic Island compact trailing UI
                Image(systemName: context.state.isRunning ? "timer" : "timer.circle")
                    .foregroundColor(context.state.isRunning ? .red : .orange)
            } minimal: {
                // Dynamic Island minimal UI when space is very constrained
                Image(systemName: "timer")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PomodoroAttributes>
    
    var body: some View {
        VStack {
            HStack {
                Text(context.state.goalEmoji)
                    .font(.title)
                
                VStack(alignment: .leading) {
                    Text("Pomodoro Timer")
                        .font(.headline)
                    
                    Text(context.state.goalName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(timeString(from: context.state.remainingTime))
                    .font(.system(.title2, design: .rounded))
                    .monospacedDigit()
                    .fontWeight(.bold)
            }
            
            ProgressView(value: Double(context.state.remainingTime), total: Double(context.state.pomodoroLength * 60))
                .progressViewStyle(LinearProgressViewStyle(tint: context.state.isRunning ? .red : .orange))
            
            HStack {
                Text(context.attributes.startTime, style: .time)
                    .font(.caption)
                
                Spacer()
                
                Text(context.state.isRunning ? "Running" : "Paused")
                    .font(.caption)
                    .foregroundColor(context.state.isRunning ? .green : .orange)
            }
            .padding(.top, 4)
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.2))
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

#endif

// Preview provider for the Widget
#if DEBUG
@available(iOS 16.1, *)
struct PomodoroWidgetLiveActivity_Previews: PreviewProvider {
    static let attributes = PomodoroAttributes(
        startTime: Date(),
        timerName: "Pomodoro Timer"
    )
    
    static let contentState = PomodoroAttributes.ContentState(
        remainingTime: 1500,
        pomodoroLength: 25,
        goalName: "Develop iOS App",
        goalEmoji: "📱",
        isRunning: true,
        endTime: Date().addingTimeInterval(1500)
    )
    
    static var previews: some View {
        #if os(iOS)
        if #available(iOS 16.1, *) {
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.compact))
                .previewDisplayName("Compact")
            
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
                .previewDisplayName("Expanded")
            
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
                .previewDisplayName("Minimal")
            
            attributes
                .previewContext(contentState, viewKind: .content)
                .previewDisplayName("Lock Screen")
        }
        #endif
    }
}
#endif
import SwiftUI

struct MacContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var showFileSelectButton = false
    @State private var errorMessage: String?
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Pomodoro Timer")
                .font(.headline)
                .padding(.top, 8)
            
            if isLoading {
                ProgressView("Loading goals...")
                    .padding()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoading = false
                        }
                    }
            } else if let error = errorMessage {
                VStack(spacing: 8) {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        timerManager.loadGoals()
                    }
                    .padding(.bottom, 4)
                    
                    if showFileSelectButton {
                        Button("Select Goals File") {
                            CSVManager.shared.promptForGoalsFile { success in
                                if success {
                                    timerManager.loadGoals()
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                }
            } else {
                // Pomodoro length selector - now converts to label when running
                HStack {
                    Text("Length:")
                        .frame(width: 60, alignment: .leading)
                    
                    if timerManager.isTimerRunning {
                        // Show as static text when timer is running
                        Text("\(timerManager.pomodoroLength) min")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        // Show as numeric input when timer is not running
                        TextField("Minutes", value: $timerManager.pomodoroLength, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                            .onChange(of: timerManager.pomodoroLength) { newValue in
                                // Enforce minimum and maximum values
                                if newValue < 1 {
                                    timerManager.pomodoroLength = 1
                                } else if newValue > 120 {
                                    timerManager.pomodoroLength = 120
                                }
                                timerManager.remainingTime = timerManager.pomodoroLength * 60
                            }
                    }
                }
                .padding(.horizontal)
                
                // Goal selector
                HStack {
                    Text("Goal:")
                        .frame(width: 60, alignment: .leading)
                    
                    if timerManager.goals.isEmpty {
                        Text("No goals available")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("", selection: $timerManager.selectedGoalIndex) {
                            ForEach(0..<timerManager.goals.count, id: \.self) { index in
                                Text("\(timerManager.goals[index].emoji) \(timerManager.goals[index].name)").tag(index)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .disabled(timerManager.isTimerRunning) // Disable when timer is running
                    }
                }
                .padding(.horizontal)
                
                // Additional goal info
                if !timerManager.goals.isEmpty {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Type:")
                                    .fontWeight(.medium)
                                Text(timerManager.goals[timerManager.selectedGoalIndex].type)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Status:")
                                    .fontWeight(.medium)
                                Text(timerManager.goals[timerManager.selectedGoalIndex].status)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Priority:")
                                    .fontWeight(.medium)
                                Text(String(format: "%.1f", timerManager.goals[timerManager.selectedGoalIndex].priority))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Context:")
                                    .fontWeight(.medium)
                                Text(timerManager.goals[timerManager.selectedGoalIndex].context)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !timerManager.goals[timerManager.selectedGoalIndex].due.isEmpty {
                                HStack {
                                    Text("Due:")
                                        .fontWeight(.medium)
                                    Text(timerManager.goals[timerManager.selectedGoalIndex].due)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                }
                
                // Timer display
                Text(timerManager.timeString)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .padding()
                
                // Control buttons - Now with 3 buttons when timer is running
                HStack(spacing: 20) {
                    Button(action: {
                        timerManager.toggleTimer()
                    }) {
                        Text(timerManager.isTimerRunning ? "Pause" : "Start")
                            .frame(width: 80)
                            .padding(.vertical, 8)
                            .background(timerManager.isTimerRunning ? Color.orange : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Only show Finish button when timer is running
                    if timerManager.isTimerRunning {
                        Button(action: {
                            timerManager.finishPomodoroEarly()
                        }) {
                            Text("Finish")
                                .frame(width: 80)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button(action: {
                        timerManager.resetTimer()
                    }) {
                        Text("Reset")
                            .frame(width: 80)
                            .padding(.vertical, 8)
                            .background(Color.secondary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(timerManager.isTimerRunning && timerManager.remainingTime == timerManager.pomodoroLength * 60)
                }
                .padding(.bottom, 4)
                
                // Only show Change Goals button when timer is not running
                if !timerManager.isTimerRunning {
                    Button("Change Goals File") {
                        CSVManager.shared.promptForGoalsFile { success in
                            if success {
                                timerManager.loadGoals()
                            }
                        }
                    }
                    .font(.caption)
                    .padding(.bottom, 8)
                }
            }
        }
        .padding()
        .frame(width: 300, height: 450)
        .onAppear {
            timerManager.requestNotificationPermission()
        }
    }
}

#if DEBUG
struct MacContentView_Previews: PreviewProvider {
    static var previews: some View {
        MacContentView()
            .environmentObject(TimerManager())
    }
}
#endif
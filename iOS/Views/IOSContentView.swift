import SwiftUI

struct IOSContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var showFileSelectButton = false
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var showGoalDetail = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error: error)
                    } else {
                        mainContentView
                    }
                }
                .padding()
                .navigationTitle("Pomodoro Timer")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gear")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .environmentObject(timerManager)
                }
                .sheet(isPresented: $showGoalDetail) {
                    if timerManager.selectedGoalIndex < timerManager.goals.count {
                        GoalDetailView(goal: timerManager.goals[timerManager.selectedGoalIndex])
                    }
                }
            }
        }
        .onAppear {
            // Slight delay to allow UI to render before loading goals
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
            
            timerManager.requestNotificationPermission()
            
            // Setup for Live Activity
            setupLiveActivity()
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack {
            ProgressView("Loading goals...")
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Text("Error: \(error)")
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                timerManager.loadGoals()
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 4)
            
            if showFileSelectButton {
                Button("Select Goals File") {
                    CSVManager.shared.promptForGoalsFile { success in
                        if success {
                            timerManager.loadGoals()
                        }
                    }
                }
                .buttonStyle(.bordered)
                .padding(.bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mainContentView: some View {
        VStack(spacing: 30) {
            // Goal Selection
            goalSelectionView
                .padding(.top, 20)
            
            Spacer()
            
            // Timer Display
            timerDisplayView
            
            Spacer()
            
            // Controls
            controlsView
                .padding(.bottom, 40)
        }
    }
    
    private var goalSelectionView: some View {
        VStack(spacing: 12) {
            if timerManager.goals.isEmpty {
                Text("No goals available")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            } else {
                Menu {
                    ForEach(0..<timerManager.goals.count, id: \.self) { index in
                        Button(action: {
                            timerManager.selectedGoalIndex = index
                        }) {
                            HStack {
                                Text("\(timerManager.goals[index].emoji) \(timerManager.goals[index].name)")
                                
                                if index == timerManager.selectedGoalIndex {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .disabled(timerManager.isTimerRunning)
                    }
                } label: {
                    HStack {
                        if timerManager.selectedGoalIndex < timerManager.goals.count {
                            Text("\(timerManager.goals[timerManager.selectedGoalIndex].emoji) \(timerManager.goals[timerManager.selectedGoalIndex].name)")
                                .font(.headline)
                        } else {
                            Text("Select a goal")
                                .font(.headline)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .disabled(timerManager.isTimerRunning)
                
                // Goal Details Button
                if timerManager.selectedGoalIndex < timerManager.goals.count {
                    Button(action: {
                        showGoalDetail = true
                    }) {
                        HStack {
                            Text("View goal details")
                                .font(.caption)
                            Image(systemName: "info.circle")
                                .font(.caption)
                        }
                    }
                    .disabled(timerManager.isTimerRunning)
                }
            }
        }
    }
    
    private var timerDisplayView: some View {
        VStack(spacing: 20) {
            // Pomodoro Length Selector (only visible when not running)
            if !timerManager.isTimerRunning {
                Stepper(value: $timerManager.pomodoroLength, in: 1...120) {
                    Text("Duration: \(timerManager.pomodoroLength) minutes")
                        .font(.headline)
                }
                .padding(.horizontal)
                .onChange(of: timerManager.pomodoroLength) { _ in
                    timerManager.remainingTime = timerManager.pomodoroLength * 60
                }
            }
            
            // Timer Circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                
                // Progress circle
                Circle()
                    .trim(from: 0.0, to: CGFloat(timerManager.remainingTime) / CGFloat(timerManager.pomodoroLength * 60))
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundColor(timerManager.isTimerRunning ? Color.red : Color.blue)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: timerManager.remainingTime)
                
                // Timer text
                VStack {
                    Text(timerManager.timeString)
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    if timerManager.isTimerRunning {
                        Text("Running")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 250, height: 250)
        }
    }
    
    private var controlsView: some View {
        VStack(spacing: 15) {
            HStack(spacing: 20) {
                Button(action: {
                    timerManager.toggleTimer()
                }) {
                    Text(timerManager.isTimerRunning ? "Pause" : "Start")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 120, height: 50)
                        .background(timerManager.isTimerRunning ? Color.orange : Color.green)
                        .cornerRadius(15)
                }
                
                Button(action: {
                    timerManager.resetTimer()
                }) {
                    Text("Reset")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 120, height: 50)
                        .background(Color.secondary)
                        .cornerRadius(15)
                }
                .disabled(timerManager.isTimerRunning && timerManager.remainingTime == timerManager.pomodoroLength * 60)
            }
            
            // Finish Early button (only when timer is running)
            if timerManager.isTimerRunning {
                Button(action: {
                    timerManager.finishPomodoroEarly()
                }) {
                    Text("Finish Early")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 260, height: 50)
                        .background(Color.blue)
                        .cornerRadius(15)
                }
            }
            
            // File selection (only when timer is not running)
            if !timerManager.isTimerRunning {
                Button("Change Goals File") {
                    CSVManager.shared.promptForGoalsFile { success in
                        if success {
                            timerManager.loadGoals()
                        }
                    }
                }
                .font(.caption)
                .padding(.top, 10)
            }
        }
    }
    
    // MARK: - Live Activity Setup
    
    private func setupLiveActivity() {
        // We'll implement this in a separate file
        #if os(iOS)
        // Setup code for ActivityKit will go here
        #endif
    }
}

// MARK: - Supporting Views

struct GoalDetailView: View {
    let goal: Goal
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    detailRow(title: "Name", value: "\(goal.emoji) \(goal.name)")
                    detailRow(title: "Type", value: goal.type)
                    detailRow(title: "Status", value: goal.status)
                    detailRow(title: "Priority", value: String(format: "%.1f", goal.priority))
                    detailRow(title: "Context", value: goal.context)
                    
                    if !goal.due.isEmpty {
                        detailRow(title: "Due", value: goal.due)
                    }
                }
            }
            .navigationTitle("Goal Details")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Timer Settings")) {
                    Stepper(value: $timerManager.pomodoroLength, in: 1...120) {
                        Text("Default Duration: \(timerManager.pomodoroLength) minutes")
                    }
                    .disabled(timerManager.isTimerRunning)
                    .onChange(of: timerManager.pomodoroLength) { _ in
                        if !timerManager.isTimerRunning {
                            timerManager.remainingTime = timerManager.pomodoroLength * 60
                        }
                    }
                }
                
                Section(header: Text("Files")) {
                    Button("Change Goals CSV File") {
                        CSVManager.shared.promptForGoalsFile { success in
                            if success {
                                timerManager.loadGoals()
                            }
                        }
                    }
                    .disabled(timerManager.isTimerRunning)
                    
                    Button("Change Pomodoro Log File") {
                        CSVManager.shared.promptForPomosFile { _ in }
                    }
                    .disabled(timerManager.isTimerRunning)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#if DEBUG
struct IOSContentView_Previews: PreviewProvider {
    static var previews: some View {
        IOSContentView()
            .environmentObject(TimerManager())
    }
}
#endif
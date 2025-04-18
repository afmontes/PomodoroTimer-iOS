import SwiftUI
import UserNotifications

@main
struct PomodoroTimerApp: App {
    // Shared environment objects
    @StateObject private var timerManager = TimerManager()
    
    #if os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) var appDelegate
    #endif
    
    init() {
        // Request notification permissions on app start
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }
    
    var body: some Scene {
        #if os(macOS)
        // macOS implementation - menu bar app
        Settings {
            EmptyView()
                .environmentObject(timerManager)
        }
        .onChange(of: timerManager.isTimerRunning) { newValue in
            // Update app delegate when timer state changes
            appDelegate.timerValue = timerManager.timeString
            appDelegate.isTimerRunning = newValue
            appDelegate.updateMenuBar()
        }
        .onChange(of: timerManager.remainingTime) { _ in
            // Update app delegate when timer value changes
            appDelegate.timerValue = timerManager.timeString
            appDelegate.updateMenuBar()
        }
        #else
        // iOS implementation - regular app
        WindowGroup {
            IOSContentView()
                .environmentObject(timerManager)
        }
        #endif
    }
}

#if os(macOS)
// macOS-specific AppDelegate to handle menu bar functionality
class MacAppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    @Published var timerValue: String = "25:00"
    @Published var isTimerRunning: Bool = false
    
    private let iconOnlyWidth: CGFloat = 30 // Width when only showing icon
    private let iconWithTimerWidth: CGFloat = 90 // Width when showing icon + timer
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the SwiftUI view for the popover
        let contentView = MacContentView()
        
        // Create the popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 450)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        
        // Create the status item with initial width for just the icon
        statusItem = NSStatusBar.system.statusItem(withLength: iconOnlyWidth)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Timer")
            
            // Center the text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            // Create the initial text (empty when not running)
            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle,
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            ]
            
            button.attributedTitle = NSAttributedString(string: "", attributes: attributes)
            button.action = #selector(togglePopover)
        }
        
        updateMenuBar()
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    func updateMenuBar() {
        if let button = statusItem.button {
            // Update status item width based on timer state
            if isTimerRunning {
                statusItem.length = iconWithTimerWidth
            } else {
                statusItem.length = iconOnlyWidth
            }
            
            // Create text attributes with centered alignment
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            // Use a monospaced font for the timer to prevent width changes
            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle,
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            ]
            
            // Only show timer text when running
            let displayText = isTimerRunning ? timerValue : ""
            button.attributedTitle = NSAttributedString(string: displayText, attributes: attributes)
            
            // Ensure the icon is always visible
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Timer")
            
            // Adjust icon position when timer is running
            if isTimerRunning {
                button.imagePosition = .imageLeft
            } else {
                button.imagePosition = .imageOnly
            }
        }
    }
}
#endif
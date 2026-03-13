import AppKit
import SwiftUI

final class ReminderWindowManager {
    static let shared = ReminderWindowManager()
    private var panel: NSPanel?
    
    private init() {}
    
    func show(standDuration: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.panel?.orderOut(nil)
            self?.panel = nil
            
            let state = StandUpState.shared
            let content = ReminderWindowView(
                standDuration: standDuration,
                onStood: { state.userStood() },
                onPostpone: { state.postpone15Minutes() },
                onDismiss: { [weak self] in self?.close() }
            )
            let hosting = NSHostingView(rootView: content)
            hosting.frame.size = NSSize(width: 320, height: 240)
            
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 240),
                styleMask: [.titled, .closable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.contentView = hosting
            panel.title = "Legday"
            panel.isFloatingPanel = true
            panel.becomesKeyOnlyIfNeeded = false
            panel.hidesOnDeactivate = false
            panel.level = .floating
            panel.isReleasedWhenClosed = false
            
            self?.panel = panel
            panel.center()
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func close() {
        DispatchQueue.main.async { [weak self] in
            self?.panel?.orderOut(nil)
            self?.panel = nil
        }
    }
}

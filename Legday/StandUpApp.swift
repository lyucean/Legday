import SwiftUI
import AppKit

final class StandUpAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
        let currentPid = ProcessInfo.processInfo.processIdentifier
        let other = running.first { $0.processIdentifier != currentPid }
        if let other = other {
            other.activate(options: [.activateAllWindows])
            NSApplication.shared.terminate(nil)
        }
    }
}

@main
struct StandUpApp: App {
    @NSApplicationDelegateAdaptor(StandUpAppDelegate.self) var appDelegate
    @StateObject private var state = StandUpState.shared
    @StateObject private var settings = SettingsStore.shared
    
    init() {
        NotificationManager.shared.requestAuthorization { _ in }
    }
    
    var body: some Scene {
        MenuBarExtra {
            MainPopupView()
                .environmentObject(state)
                .environmentObject(settings)
                .frame(width: 300)
        } label: {
            MenuBarLabel(state: state, settings: settings)
        }
        .menuBarExtraStyle(.window)
        
        WindowGroup("Настройки", id: "settings") {
            SettingsView()
                .environmentObject(settings)
                .frame(width: 340, height: 620)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 340, height: 620)
        .windowBackgroundDragBehavior(.enabled)
        .commandsRemoved()
    }
}

private let purpleLight = Color(red: 0.65, green: 0.48, blue: 0.98)
private let trayMuted = Color(red: 0.42, green: 0.42, blue: 0.54)

private let purpleNS = NSColor(red: 0.65, green: 0.48, blue: 0.98, alpha: 1)
private let trayMutedNS = NSColor(red: 0.42, green: 0.42, blue: 0.54, alpha: 1)

struct MenuBarLabel: View {
    @ObservedObject var state: StandUpState
    @ObservedObject var settings: SettingsStore
    
    private var trayIcon: Image? {
        let nsColor = settings.coloredIcon ? purpleNS : trayMutedNS
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            .applying(.init(paletteColors: [nsColor]))
        guard let nsImage = NSImage(systemSymbolName: state.phase == .sitting ? "chair.fill" : "figure.stand", accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return nil }
        return Image(nsImage: nsImage)
            .renderingMode(.original)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = trayIcon {
                icon
            } else {
                Image(systemName: state.phase == .sitting ? "chair.fill" : "figure.stand")
                    .font(.system(size: 14))
            }
            Text(state.formattedRemaining())
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
        }
    }
}


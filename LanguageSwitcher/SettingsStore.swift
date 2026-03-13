import Foundation
import ServiceManagement

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let reminderIntervalMinutes = "reminderIntervalMinutes"
        static let standDurationMinutes = "standDurationMinutes"
        static let soundEnabled = "soundEnabled"
        static let doNotDisturb = "doNotDisturb"
        static let launchAtLogin = "launchAtLogin"
        static let workingHours = "workingHours"
        static let coloredIcon = "coloredIcon"
    }
    
    @Published var coloredIcon: Bool {
        didSet { defaults.set(coloredIcon, forKey: Keys.coloredIcon) }
    }
    
    @Published var reminderIntervalMinutes: Int {
        didSet { defaults.set(reminderIntervalMinutes, forKey: Keys.reminderIntervalMinutes) }
    }
    
    @Published var standDurationMinutes: Int {
        didSet { defaults.set(standDurationMinutes, forKey: Keys.standDurationMinutes) }
    }
    
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }
    
    @Published var doNotDisturb: Bool {
        didSet { defaults.set(doNotDisturb, forKey: Keys.doNotDisturb) }
    }
    
    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            setLaunchAtLogin(launchAtLogin)
        }
    }
    
    @Published var workingHours: WorkingHoursPreset {
        didSet { defaults.set(workingHours.rawValue, forKey: Keys.workingHours) }
    }
    
    enum WorkingHoursPreset: String, CaseIterable {
        case always = "Всегда"
        case h8_18 = "8:00-18:00"
        case h9_19 = "9:00-19:00"
        
        var startHour: Int? {
            switch self {
            case .always: return nil
            case .h8_18: return 8
            case .h9_19: return 9
            }
        }
        var endHour: Int? {
            switch self {
            case .always: return nil
            case .h8_18: return 18
            case .h9_19: return 19
            }
        }
    }
    
    static let reminderIntervalOptions = [30, 60, 90]
    static let standDurationOptions = [10, 20, 30]
    
    private init() {
        self.reminderIntervalMinutes = defaults.object(forKey: Keys.reminderIntervalMinutes) as? Int ?? 60
        self.standDurationMinutes = defaults.object(forKey: Keys.standDurationMinutes) as? Int ?? 20
        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        self.doNotDisturb = defaults.object(forKey: Keys.doNotDisturb) as? Bool ?? false
        self.launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? true
        self.coloredIcon = defaults.object(forKey: Keys.coloredIcon) as? Bool ?? true
        let raw = defaults.string(forKey: Keys.workingHours) ?? WorkingHoursPreset.h9_19.rawValue
        self.workingHours = WorkingHoursPreset(rawValue: raw) ?? .h9_19
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Ignore: may need entitlement or user approval
            }
        }
    }
}

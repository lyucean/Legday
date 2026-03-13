import Foundation
import Combine
import AppKit

enum StandUpPhase: String {
    case sitting
    case standing
}

final class StandUpState: ObservableObject {
    static let shared = StandUpState()
    
    @Published var phase: StandUpPhase = .sitting
    @Published var remainingSeconds: Int = 0
    @Published var isPaused: Bool = false
    @Published var nextReminderDate: Date = Date()
    @Published var standsToday: Int = 0
    @Published var standingMinutesToday: Int = 0
    @Published var streakDays: Int = 0
    @Published var pendingNotificationReminder: Bool = false
    
    private var timer: Timer?
    private var phaseEndDate: Date?
    private var standingPhaseStartDate: Date?
    private let calendar = Calendar.current
    private var lastResetDate: Date?
    
    var settings: SettingsStore { SettingsStore.shared }
    
    private init() {
        loadDailyStats()
        resetIfNewDay()
        startPhase(.sitting, durationSeconds: settings.reminderIntervalMinutes * 60)
    }
    
    func startPhase(_ newPhase: StandUpPhase, durationSeconds: Int) {
        if phase == .standing, let start = standingPhaseStartDate {
            addActualStandingMinutes(since: start)
        }
        standingPhaseStartDate = nil
        phase = newPhase
        phaseEndDate = Date().addingTimeInterval(TimeInterval(durationSeconds))
        remainingSeconds = durationSeconds
        nextReminderDate = phaseEndDate ?? Date()
        if phase == .sitting {
            scheduleNotification(in: durationSeconds)
        } else {
            standingPhaseStartDate = Date()
            NotificationManager.shared.cancelStandReminder()
        }
        startTimer()
    }
    
    func remindNow() {
        guard phase == .sitting else { return }
        startPhase(.standing, durationSeconds: settings.standDurationMinutes * 60)
        recordStandCount()
    }
    
    func userStood() {
        pendingNotificationReminder = false
        startPhase(.standing, durationSeconds: settings.standDurationMinutes * 60)
        recordStandCount()
    }
    
    func sitDown() {
        startPhase(.sitting, durationSeconds: settings.reminderIntervalMinutes * 60)
    }
    
    func playToggleSound() {
        NSSound(named: "Tink")?.play()
    }
    
    func postpone15Minutes() {
        pendingNotificationReminder = false
        let extra = 15 * 60
        let newEnd = (phaseEndDate ?? Date()).addingTimeInterval(TimeInterval(extra))
        phaseEndDate = newEnd
        remainingSeconds = max(0, Int(newEnd.timeIntervalSince(Date())))
        nextReminderDate = newEnd
        scheduleNotification(in: remainingSeconds)
    }
    
    func togglePause() {
        isPaused.toggle()
        if isPaused {
            timer?.invalidate()
            timer = nil
            NotificationManager.shared.cancelStandReminder()
        } else {
            let left = phaseEndDate?.timeIntervalSince(Date()) ?? 0
            if left > 0 {
                remainingSeconds = Int(left)
                startTimer()
                if phase == .sitting {
                    scheduleNotification(in: remainingSeconds)
                }
            } else {
                if phase == .sitting {
                    remindNow()
                } else {
                    startPhase(.sitting, durationSeconds: settings.reminderIntervalMinutes * 60)
                }
            }
        }
    }
    
    func formattedRemaining() -> String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    func nextReminderTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: nextReminderDate)
    }
    
    var timerProgress: Double {
        let total: Int
        if phase == .sitting {
            total = settings.reminderIntervalMinutes * 60
        } else {
            total = settings.standDurationMinutes * 60
        }
        guard total > 0 else { return 0 }
        return Double(total - remainingSeconds) / Double(total)
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func tick() {
        guard !isPaused, let end = phaseEndDate else { return }
        let left = Int(end.timeIntervalSince(Date()))
        if left <= 0 {
            timer?.invalidate()
            timer = nil
            if phase == .sitting {
                showStandReminder()
            } else {
                startPhase(.sitting, durationSeconds: settings.reminderIntervalMinutes * 60)
            }
            return
        }
        remainingSeconds = left
    }
    
    private func showStandReminder() {
        guard isWithinWorkingHours() else {
            startPhase(.sitting, durationSeconds: settings.reminderIntervalMinutes * 60)
            return
        }
        if settings.doNotDisturb {
            postpone15Minutes()
            return
        }
        pendingNotificationReminder = true
        if settings.soundEnabled {
            playToggleSound()
        }
        ReminderWindowManager.shared.show(standDuration: settings.standDurationMinutes)
    }
    
    private func scheduleNotification(in seconds: Int) {
        guard settings.workingHours == .always || isWithinWorkingHours() else { return }
        NotificationManager.shared.scheduleStandReminder(
            in: seconds,
            standDuration: settings.standDurationMinutes,
            sound: settings.soundEnabled
        )
    }
    
    func isWithinWorkingHours() -> Bool {
        let preset = settings.workingHours
        guard let start = preset.startHour, let end = preset.endHour else { return true }
        let hour = calendar.component(.hour, from: Date())
        return hour >= start && hour < end
    }
    
    private func recordStandCount() {
        standsToday += 1
        saveDailyStats()
        updateStreak()
    }
    
    private func addActualStandingMinutes(since startDate: Date) {
        let elapsed = max(0, Int(Date().timeIntervalSince(startDate)))
        let minutes = elapsed / 60
        if minutes > 0 {
            standingMinutesToday += minutes
            saveDailyStats()
        }
    }
    
    private func loadDailyStats() {
        let key = dayKey()
        standsToday = UserDefaults.standard.integer(forKey: "stands_\(key)")
        standingMinutesToday = UserDefaults.standard.integer(forKey: "standingMin_\(key)")
        streakDays = UserDefaults.standard.integer(forKey: "streakDays")
    }
    
    private func saveDailyStats() {
        let key = dayKey()
        UserDefaults.standard.set(standsToday, forKey: "stands_\(key)")
        UserDefaults.standard.set(standingMinutesToday, forKey: "standingMin_\(key)")
        UserDefaults.standard.set(streakDays, forKey: "streakDays")
    }
    
    private func dayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func resetIfNewDay() {
        let key = dayKey()
        if lastResetDate == nil {
            lastResetDate = Date()
            return
        }
        let lastKey = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: lastResetDate!)
        }()
        if key != lastKey {
            standsToday = 0
            standingMinutesToday = 0
            lastResetDate = Date()
            saveDailyStats()
        }
    }
    
    private func updateStreak() {
        let key = dayKey()
        let lastStreakKey = UserDefaults.standard.string(forKey: "lastStreakDay") ?? ""
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayKey = dayKey(for: yesterday)
        if lastStreakKey == yesterdayKey {
            streakDays += 1
        } else if lastStreakKey != key {
            streakDays = 1
        }
        UserDefaults.standard.set(key, forKey: "lastStreakDay")
        UserDefaults.standard.set(streakDays, forKey: "streakDays")
    }
    
    private func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

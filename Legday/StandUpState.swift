import Foundation
import Combine
import AppKit

enum StandUpPhase: String {
    case sitting
    case standing
}

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: String
    var durationMinutes: Int?
    init(id: UUID, date: Date, type: String, durationMinutes: Int? = nil) {
        self.id = id
        self.date = date
        self.type = type
        self.durationMinutes = durationMinutes
    }
    enum CodingKeys: String, CodingKey { case id, date, type, durationMinutes }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        type = try c.decode(String.self, forKey: .type)
        durationMinutes = try c.decodeIfPresent(Int.self, forKey: .durationMinutes)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(durationMinutes, forKey: .durationMinutes)
    }
    static func stand(at date: Date = Date(), durationMinutes: Int? = nil) -> JournalEntry {
        JournalEntry(id: UUID(), date: date, type: "stand", durationMinutes: durationMinutes)
    }
    static func sit(at date: Date = Date()) -> JournalEntry {
        JournalEntry(id: UUID(), date: date, type: "sit", durationMinutes: nil)
    }
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
    /// Для мигания в трее: true = иконка яркая, false = приглушённая.
    @Published var trayBlinkVisible: Bool = true
    /// Включить тестовое мигание из настроек на несколько секунд.
    @Published var isTestTrayBlink: Bool = false
    @Published var journalEntries: [JournalEntry] = []
    
    private var timer: Timer?
    private var blinkTimer: Timer?
    private var phaseEndDate: Date?
    private var standingPhaseStartDate: Date?
    private let calendar = Calendar.current
    private var lastResetDate: Date?
    
    var settings: SettingsStore { SettingsStore.shared }
    
    private init() {
        loadDailyStats()
        loadJournal()
        resetIfNewDay()
        if !restoreTimerState() {
            startPhase(.sitting, durationSeconds: settings.reminderIntervalMinutes * 60)
        }
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
        saveTimerState()
    }
    
    func remindNow() {
        guard phase == .sitting else { return }
        startPhase(.standing, durationSeconds: settings.standDurationMinutes * 60)
        recordStandCount()
    }
    
    func userStood() {
        pendingNotificationReminder = false
        stopBlinkTimerIfNeeded()
        addJournalEntry(.stand())
        startPhase(.standing, durationSeconds: settings.standDurationMinutes * 60)
        recordStandCount()
    }
    
    func sitDown() {
        if let idx = journalEntries.firstIndex(where: { $0.type == "stand" }) {
            let stand = journalEntries[idx]
            let minutes = max(0, Int(Date().timeIntervalSince(stand.date) / 60))
            journalEntries[idx] = JournalEntry(id: stand.id, date: stand.date, type: "stand", durationMinutes: minutes)
        }
        addJournalEntry(.sit())
        startPhase(.sitting, durationSeconds: settings.reminderIntervalMinutes * 60)
    }
    
    func addJournalEntry(_ entry: JournalEntry) {
        journalEntries.insert(entry, at: 0)
        if journalEntries.count > 500 { journalEntries.removeLast() }
        saveJournal()
    }
    
    func removeJournalEntry(id: UUID) {
        journalEntries.removeAll { $0.id == id }
        saveJournal()
    }

    /// Сбросить всю историю: журнал и счётчики (стояния, минуты, серия).
    func clearAllHistory() {
        journalEntries = []
        saveJournal()
        standsToday = 0
        standingMinutesToday = 0
        streakDays = 0
        UserDefaults.standard.removeObject(forKey: "lastStreakDay")
        saveDailyStats()
    }
    
    private func loadJournal() {
        guard let data = UserDefaults.standard.data(forKey: "journalEntries"),
              let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) else { return }
        journalEntries = decoded
    }
    
    private func saveJournal() {
        guard let data = try? JSONEncoder().encode(journalEntries) else { return }
        UserDefaults.standard.set(data, forKey: "journalEntries")
    }
    
    func playToggleSound() {
        guard let sound = NSSound(named: "Tink") else { return }
        sound.volume = 1.0
        sound.play()
    }

    /// Добавить или убрать минуты у текущего таймера (+5 / -5 / -1).
    func adjustMinutes(_ delta: Int) {
        guard let end = phaseEndDate else { return }
        let newEnd = end.addingTimeInterval(TimeInterval(delta * 60))
        let now = Date()
        let newRemaining = Int(newEnd.timeIntervalSince(now))
        if newRemaining <= 0 {
            if phase == .sitting {
                showStandReminder()
            } else {
                startPhase(.sitting, durationSeconds: settings.reminderIntervalMinutes * 60)
            }
            return
        }
        phaseEndDate = newEnd
        remainingSeconds = newRemaining
        nextReminderDate = newEnd
        pendingNotificationReminder = false
        stopBlinkTimerIfNeeded()
        if phase == .sitting {
            scheduleNotification(in: remainingSeconds)
        }
        startTimer()
        saveTimerState()
    }
    
    func postpone15Minutes() {
        pendingNotificationReminder = false
        stopBlinkTimerIfNeeded()
        let extra = 15 * 60
        let newEnd = (phaseEndDate ?? Date()).addingTimeInterval(TimeInterval(extra))
        phaseEndDate = newEnd
        remainingSeconds = max(0, Int(newEnd.timeIntervalSince(Date())))
        nextReminderDate = newEnd
        scheduleNotification(in: remainingSeconds)
        startTimer()
        saveTimerState()
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
        saveTimerState()
    }
    
    func formattedRemaining() -> String {
        let secs = abs(remainingSeconds)
        let m = secs / 60
        let s = secs % 60
        if remainingSeconds < 0 {
            return "-" + String(format: "%02d:%02d", m, s)
        }
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
        let progress = Double(total - remainingSeconds) / Double(total)
        return min(max(progress, 0), 1)
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
        if left <= 0 && phase == .sitting {
            timer?.invalidate()
            timer = nil
            remainingSeconds = 0
            if !pendingNotificationReminder {
                showStandReminder()
            }
            return
        }
        if left <= 0 && phase == .standing {
            timer?.invalidate()
            timer = nil
            let shouldPlaySound = settings.soundEnabled
            if settings.autoStartSittingTimer {
                startPhase(.sitting, durationSeconds: settings.reminderIntervalMinutes * 60)
            } else {
                stopSittingTimerAndBlink()
            }
            if shouldPlaySound {
                DispatchQueue.main.async { [weak self] in
                    self?.playToggleSound()
                }
            }
            return
        }
        remainingSeconds = left
    }
    
    private func showStandReminder() {
        pendingNotificationReminder = true
        startBlinkTimerIfNeeded()
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
    
    /// Вызывать при активации приложения: если время напоминания уже прошло, показываем его (таймер в фоне мог не сработать).
    func checkIfReminderDue() {
        guard !isPaused, let end = phaseEndDate else { return }
        if end.timeIntervalSince(Date()) > 0 { return }
        timer?.invalidate()
        timer = nil
        if phase == .sitting {
            showStandReminder()
        } else {
            let shouldPlaySound = settings.soundEnabled
            if settings.autoStartSittingTimer {
                startPhase(.sitting, durationSeconds: settings.reminderIntervalMinutes * 60)
            } else {
                stopSittingTimerAndBlink()
            }
            if shouldPlaySound {
                DispatchQueue.main.async { [weak self] in
                    self?.playToggleSound()
                }
            }
        }
    }

    /// После стояния: не запускать обратный отсчёт сидения, а остановить на 00:00 и мигать.
    private func stopSittingTimerAndBlink() {
        phase = .sitting
        phaseEndDate = Date()
        remainingSeconds = 0
        nextReminderDate = Date()
        pendingNotificationReminder = true
        startBlinkTimerIfNeeded()
        saveTimerState()
    }

    /// Запустить тестовое мигание в трее на 5 секунд (кнопка «Моргнуть» в настройках).
    func startTestTrayBlink() {
        isTestTrayBlink = true
        startBlinkTimerIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.isTestTrayBlink = false
            self?.stopBlinkTimerIfNeeded()
        }
    }

    private func startBlinkTimerIfNeeded() {
        guard (pendingNotificationReminder || isTestTrayBlink) && blinkTimer == nil else { return }
        trayBlinkVisible = true
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if self.pendingNotificationReminder || self.isTestTrayBlink {
                    self.objectWillChange.send()
                    self.trayBlinkVisible.toggle()
                } else {
                    self.stopBlinkTimerIfNeeded()
                }
            }
        }
        RunLoop.main.add(blinkTimer!, forMode: .common)
    }

    private func stopBlinkTimerIfNeeded() {
        guard !pendingNotificationReminder && !isTestTrayBlink else { return }
        blinkTimer?.invalidate()
        blinkTimer = nil
        trayBlinkVisible = true
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

    private func saveTimerState() {
        let ud = UserDefaults.standard
        ud.set(phase.rawValue, forKey: "timer_phase")
        ud.set(phaseEndDate?.timeIntervalSince1970, forKey: "timer_phaseEndDate")
        ud.set(isPaused, forKey: "timer_paused")
    }

    /// Восстанавливает фазу и оставшееся время после перезапуска. Возвращает true, если состояние восстановлено.
    private func restoreTimerState() -> Bool {
        let ud = UserDefaults.standard
        guard let phaseRaw = ud.string(forKey: "timer_phase"),
              let phase = StandUpPhase(rawValue: phaseRaw) else { return false }
        guard let endTimestamp = ud.object(forKey: "timer_phaseEndDate") as? Double else { return false }
        let savedEnd = Date(timeIntervalSince1970: endTimestamp)
        let paused = ud.bool(forKey: "timer_paused")

        self.phase = phase
        self.phaseEndDate = savedEnd
        self.isPaused = paused
        let left = Int(savedEnd.timeIntervalSince(Date()))
        self.remainingSeconds = left
        self.nextReminderDate = savedEnd

        if left <= 0 {
            if phase == .sitting {
                self.remainingSeconds = 0
                showStandReminder()
            } else {
                let shouldPlaySound = settings.soundEnabled
                if settings.autoStartSittingTimer {
                    startPhase(.sitting, durationSeconds: settings.reminderIntervalMinutes * 60)
                } else {
                    stopSittingTimerAndBlink()
                }
                if shouldPlaySound {
                    DispatchQueue.main.async { [weak self] in
                        self?.playToggleSound()
                    }
                }
            }
            return true
        }

        if phase == .standing {
            let standDuration = TimeInterval(settings.standDurationMinutes * 60)
            standingPhaseStartDate = savedEnd.addingTimeInterval(-standDuration)
        }
        if paused {
            timer = nil
        } else {
            startTimer()
            if phase == .sitting {
                scheduleNotification(in: remainingSeconds)
            }
        }
        return true
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

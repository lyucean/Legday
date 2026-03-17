import SwiftUI
import AppKit

private let bgDark = Color(red: 0.086, green: 0.086, blue: 0.165)
private let purple = Color(red: 0.49, green: 0.23, blue: 0.93)
private let purpleLight = Color(red: 0.65, green: 0.48, blue: 0.98)
private let textPrimary = Color(red: 0.89, green: 0.85, blue: 0.95)
private let textMuted = Color(red: 0.42, green: 0.42, blue: 0.54)
private let borderSubtle = Color.white.opacity(0.05)

struct MainPopupView: View {
    @EnvironmentObject var state: StandUpState
    @EnvironmentObject var settings: SettingsStore
    @State private var showingSettings = false
    @State private var showingJournal = false
    @State private var backButtonHovered = false
    @State private var journalButtonHovered = false
    @State private var pauseButtonHovered = false
    @State private var settingsButtonHovered = false
    @State private var standButtonHovered = false
    @State private var exitButtonHovered = false

    var body: some View {
        VStack(spacing: 0) {
            if showingSettings {
                settingsHeader
                SettingsFormContent()
                    .environmentObject(settings)
            } else if showingJournal {
                journalHeader
                ZStack(alignment: .center) {
                    journalContent
                    if showClearHistoryConfirm {
                        journalClearHistoryOverlay
                    }
                }
            } else {
                header
                stateBlock
                timerRing
                statsRow
                actionButtons
                footer
            }
        }
        .frame(width: showingSettings ? 340 : 300)
        .frame(minHeight: (showingSettings || showingJournal) ? 760 : nil, maxHeight: 900)
        .background(bgDark)
        .onAppear { state.resetIfNewDay() }
    }

    private var settingsHeader: some View {
        HStack {
            Button(action: { showingSettings = false }) {
                Text("Назад")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(backButtonHovered ? purple.opacity(0.2) : Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(purple, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .onHover { backButtonHovered = $0 }
            Spacer()
        }
        .overlay(alignment: .center) {
            Text("Настройки")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) { Divider().background(borderSubtle) }
    }

    private var header: some View {
        HStack {
            Image(systemName: state.phase == .sitting ? "chair.fill" : "figure.stand")
                .font(.system(size: 18))
                .foregroundStyle(settings.coloredIcon ? purpleLight : textMuted)
            Text("Legday")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(textPrimary)
            Spacer()
            Circle()
                .fill(purple)
                .frame(width: 7, height: 7)
                .shadow(color: purple.opacity(0.8), radius: 3)
            Button(action: { showingJournal = true }) {
                Image(systemName: "book.closed")
                    .font(.system(size: 13))
                    .foregroundStyle(purple)
                    .frame(width: 28, height: 28)
                    .background(journalButtonHovered ? purple.opacity(0.2) : Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(purple, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .onHover { journalButtonHovered = $0 }
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundStyle(purple)
                    .frame(width: 32, height: 28)
                    .background(settingsButtonHovered ? purple.opacity(0.2) : Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(purple, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .onHover { settingsButtonHovered = $0 }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) { Divider().background(borderSubtle) }
    }

    @State private var showClearHistoryConfirm = false

    private var journalHeader: some View {
        HStack {
            Button(action: { showingJournal = false }) {
                Text("Назад")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(backButtonHovered ? purple.opacity(0.2) : Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(purple, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .onHover { backButtonHovered = $0 }
            Spacer()
            if !state.journalEntries.isEmpty {
                Button(action: { showClearHistoryConfirm = true }) {
                    Text("Удалить все")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(purple)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .center) {
            Text("Журнал")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) { Divider().background(borderSubtle) }
    }

    private var journalClearHistoryOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture { showClearHistoryConfirm = false }
            VStack(spacing: 16) {
                Text("Сбросить всю историю?")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(textPrimary)
                Text("Очистится журнал и счётчики (стояния, минуты, серия). Таймер продолжит работать.")
                    .font(.system(size: 12))
                    .foregroundStyle(textMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    Button(action: { showClearHistoryConfirm = false }) {
                        Text("Отмена")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    Button(action: {
                        state.clearAllHistory()
                        showClearHistoryConfirm = false
                    }) {
                        Text("Удалить все")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .frame(width: 260)
            .background(bgDark)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderSubtle, lineWidth: 1))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Только сессии стояния (записи "Встал" с проставленной длительностью), сгруппированные по дням.
    private var journalSessionsByDate: [(date: Date, entries: [JournalEntry])] {
        let calendar = Calendar.current
        let sessions = state.journalEntries.filter { $0.type == "stand" && $0.durationMinutes != nil }
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { (date: $0, entries: grouped[$0]!.sorted { $0.date > $1.date }) }
    }

    private var journalContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if journalSessionsByDate.isEmpty {
                    Text("Пока нет записей")
                        .font(.system(size: 13))
                        .foregroundStyle(textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                } else {
                    ForEach(journalSessionsByDate, id: \.date) { group in
                        Text(journalDateString(group.date))
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.5)
                            .foregroundStyle(textMuted)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 6)
                        ForEach(group.entries) { entry in
                            HStack(alignment: .center) {
                                Image(systemName: "figure.stand")
                                    .font(.system(size: 12))
                                    .foregroundStyle(purple)
                                    .frame(width: 24, alignment: .leading)
                                Text(journalSessionTitle(entry))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(textPrimary)
                                Spacer()
                                Button(action: { state.removeJournalEntry(id: entry.id) }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundStyle(textMuted)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .overlay(alignment: .bottom) { Divider().background(borderSubtle) }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func journalDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f.string(from: date)
    }

    /// Формат одной сессии: "08:04 - Постоял 13 мин." Длительность ограничена таймером стояния из настроек.
    private func journalSessionTitle(_ entry: JournalEntry) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        let time = f.string(from: entry.date)
        let rawMin = entry.durationMinutes ?? 0
        let min = min(rawMin, state.settings.standDurationMinutes)
        return "\(time) - Постоял \(min) мин."
    }
    
    private var stateBlock: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(purple.opacity(0.12))
                    .frame(width: 64, height: 64)
                    .overlay(Circle().stroke(purple.opacity(0.3), lineWidth: 1.5))
                Image(systemName: state.phase == .sitting ? "chair.fill" : "figure.stand")
                    .font(.system(size: 28))
                    .foregroundStyle(purple)
            }
            .padding(.bottom, 4)
            Text("СЕЙЧАС")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(purple)
            Text(state.phase == .sitting ? "Сидите" : "Стоите")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(textPrimary)
            Text(state.phase == .sitting ? "До следующего напоминания" : "До конца подхода")
                .font(.system(size: 12))
                .foregroundStyle(textMuted)
        }
        .padding(.vertical, 20)
    }
    
    private var minusButtonDelta: Int {
        state.remainingSeconds < 5 * 60 ? -1 : -5
    }

    private var minusButtonDisabled: Bool {
        state.remainingSeconds < 60
    }

    private var timerRing: some View {
        HStack(spacing: 12) {
            Button(action: { state.adjustMinutes(minusButtonDelta) }) {
                Text(state.remainingSeconds < 5 * 60 ? "-1" : "-5")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(minusButtonDisabled ? textMuted : purpleLight)
                    .frame(width: 44, height: 44)
                    .background(purple.opacity(minusButtonDisabled ? 0.08 : 0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(minusButtonDisabled)
            ZStack {
                Circle()
                    .stroke(purple.opacity(0.12), lineWidth: 6)
                    .frame(width: 110, height: 110)
                Circle()
                    .trim(from: 0, to: state.timerProgress)
                    .stroke(purple, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: purple.opacity(0.5), radius: 4)
                VStack(spacing: 2) {
                    Text(state.formattedRemaining())
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(textPrimary)
                        .monospacedDigit()
                    Text(state.phase == .sitting ? "до стенда" : "осталось")
                        .font(.system(size: 10))
                        .foregroundStyle(textMuted)
                }
            }
            Button(action: { state.adjustMinutes(5) }) {
                Text("+5")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(purpleLight)
                    .frame(width: 44, height: 44)
                    .background(purple.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 16)
    }
    
    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(state.standsToday)", label: "стояний сегодня")
            Rectangle().fill(borderSubtle).frame(width: 1)
            statCell(value: "\(state.standingMinutesToday) мин", label: "стоя за день")
            Rectangle().fill(borderSubtle).frame(width: 1)
            statCell(value: "🔥 \(state.streakDays)", label: "дня подряд")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(alignment: .top) { Divider().background(borderSubtle) }
        .overlay(alignment: .bottom) { Divider().background(borderSubtle) }
    }
    
    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(purpleLight)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(textMuted)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button(action: {
                if state.phase == .sitting {
                    state.userStood()
                } else {
                    state.sitDown()
                }
                if settings.soundEnabled {
                    state.playToggleSound()
                }
            }) {
                Label(
                    state.phase == .sitting ? "Встать" : "Сесть",
                    systemImage: state.phase == .sitting ? "figure.stand" : "chair.fill"
                )
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: standButtonHovered
                            ? [purpleLight, purple]
                            : [purple, purple.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: standButtonHovered ? purple.opacity(0.5) : .clear, radius: 8, y: 2)
                .animation(.easeInOut(duration: 0.15), value: standButtonHovered)
            }
            .buttonStyle(.plain)
            .onHover { standButtonHovered = $0 }
            
            Button(action: { state.togglePause() }) {
                Label(state.isPaused ? "Запустить" : "Пауза", systemImage: state.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(purple)
                    .background(pauseButtonHovered ? purple.opacity(0.2) : Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(purple, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .onHover { pauseButtonHovered = $0 }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    private var footer: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Следующее в")
                    .font(.system(size: 11))
                    .foregroundStyle(textMuted)
                Text(state.nextReminderTimeString())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(purple)
            }
            Spacer()
            Button("Выйти") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 11))
            .foregroundStyle(exitButtonHovered ? textPrimary : textMuted)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(exitButtonHovered ? Color.white.opacity(0.08) : Color.clear)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(exitButtonHovered ? borderSubtle : Color.clear, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onHover { exitButtonHovered = $0 }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

#Preview {
    MainPopupView()
        .environmentObject(StandUpState.shared)
        .environmentObject(SettingsStore.shared)
        .frame(width: 300)
}

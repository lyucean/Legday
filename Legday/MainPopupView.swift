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
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(spacing: 0) {
            header
            stateBlock
            timerRing
            statsRow
            actionButtons
            footer
        }
        .background(bgDark)
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
            Button(action: {
                if let win = NSApplication.shared.windows.first(where: { $0.title == "Настройки" }) {
                    win.makeKeyAndOrderFront(nil)
                } else {
                    openWindow(id: "settings")
                }
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundStyle(textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) { Divider().background(borderSubtle) }
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
    
    private var timerRing: some View {
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
                    LinearGradient(colors: [purple, purple.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            
            Button(action: { state.togglePause() }) {
                Label(state.isPaused ? "Запустить" : "Пауза", systemImage: state.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.04))
                    .foregroundStyle(textMuted)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderSubtle, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
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
            .foregroundStyle(textMuted)
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

import SwiftUI
import AppKit

private let bgDark = Color(red: 0.086, green: 0.086, blue: 0.165)
private let purple = Color(red: 0.49, green: 0.23, blue: 0.93)
private let textPrimary = Color(red: 0.89, green: 0.85, blue: 0.95)
private let textMuted = Color(red: 0.42, green: 0.42, blue: 0.54)
private let borderSubtle = Color.white.opacity(0.05)

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        VStack(spacing: 0) {
            header
            VStack(alignment: .leading, spacing: 16) {
                sectionLabel("Расписание")
                reminderIntervalRow
                standDurationRow
                Divider().background(borderSubtle)
                sectionLabel("Уведомления")
                coloredIconRow
                soundRow
                doNotDisturbRow
                launchAtLoginRow
                showNotificationButton
                Divider().background(borderSubtle)
                workingHoursRow
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 340, height: 620)
        .background(bgDark)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            DispatchQueue.main.async {
                guard let win = NSApplication.shared.windows.first(where: { $0.title == "Настройки" }) else { return }
                win.makeKeyAndOrderFront(nil)
                win.isOpaque = false
                win.backgroundColor = .clear
                win.contentView?.wantsLayer = true
                win.contentView?.layer?.cornerRadius = 16
                win.contentView?.layer?.masksToBounds = true
                win.standardWindowButton(.closeButton)?.isHidden = true
                win.standardWindowButton(.miniaturizeButton)?.isHidden = true
                win.standardWindowButton(.zoomButton)?.isHidden = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            if let win = NSApplication.shared.windows.first(where: { $0.title == "Настройки" }) {
                win.standardWindowButton(.closeButton)?.isHidden = true
                win.standardWindowButton(.miniaturizeButton)?.isHidden = true
                win.standardWindowButton(.zoomButton)?.isHidden = true
            }
        }
    }
    
    private var header: some View {
        HStack {
            Text("Настройки")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(textPrimary)
            Spacer()
            Button(action: { dismissWindow(id: "settings") }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(textMuted)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) { Divider().background(borderSubtle) }
    }
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .medium))
            .tracking(1.5)
            .foregroundStyle(textMuted)
    }
    
    private var reminderIntervalRow: some View {
        settingsRow(
            title: "Интервал напоминания",
            subtitle: "Как часто вставать"
        ) {
            Picker("", selection: $settings.reminderIntervalMinutes) {
                ForEach(SettingsStore.reminderIntervalOptions, id: \.self) { m in
                    Text(intervalLabel(m)).tag(m)
                }
            }
            .labelsHidden()
            .frame(width: 100)
            .tint(purpleLight)
        }
    }
    
    private var standDurationRow: some View {
        settingsRow(
            title: "Время стояния",
            subtitle: "Цель за один подход"
        ) {
            Picker("", selection: $settings.standDurationMinutes) {
                ForEach(SettingsStore.standDurationOptions, id: \.self) { m in
                    Text("\(m) мин").tag(m)
                }
            }
            .labelsHidden()
            .frame(width: 100)
            .tint(purpleLight)
        }
    }
    
    private var coloredIconRow: some View {
        settingsRow(
            title: "Цветная иконка",
            subtitle: "Фиолетовая иконка в шапке и в трее"
        ) {
            Toggle("", isOn: $settings.coloredIcon)
                .toggleStyle(.switch)
                .tint(purple)
        }
    }
    
    private var soundRow: some View {
        settingsRow(
            title: "Звук",
            subtitle: "При напоминании и при переключении Встать/Сесть"
        ) {
            Toggle("", isOn: $settings.soundEnabled)
                .toggleStyle(.switch)
                .tint(purple)
        }
    }
    
    private var doNotDisturbRow: some View {
        settingsRow(
            title: "Не беспокоить",
            subtitle: "Пауза во время митингов"
        ) {
            Toggle("", isOn: $settings.doNotDisturb)
                .toggleStyle(.switch)
                .tint(purple)
        }
    }
    
    private var launchAtLoginRow: some View {
        settingsRow(
            title: "Автозапуск",
            subtitle: "Запускать при входе в систему"
        ) {
            Toggle("", isOn: $settings.launchAtLogin)
                .toggleStyle(.switch)
                .tint(purple)
        }
    }
    
    private var showNotificationButton: some View {
        Button(action: {
            if settings.soundEnabled {
                StandUpState.shared.playToggleSound()
            }
            ReminderWindowManager.shared.show(standDuration: settings.standDurationMinutes)
        }) {
            HStack(spacing: 6) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 12))
                Text("Показать уведомление")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(purpleLight)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(purple.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
    
    private var workingHoursRow: some View {
        settingsRow(
            title: "Рабочие часы",
            subtitle: "Напоминать только в это время"
        ) {
            Picker("", selection: $settings.workingHours) {
                ForEach(SettingsStore.WorkingHoursPreset.allCases, id: \.rawValue) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .labelsHidden()
            .frame(width: 120)
            .tint(purpleLight)
        }
    }
    
    private func settingsRow<C: View>(title: String, subtitle: String, @ViewBuilder control: () -> C) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(textMuted)
            }
            Spacer()
            control()
        }
    }
    
    private func intervalLabel(_ minutes: Int) -> String {
        if minutes == 60 { return "1 час" }
        if minutes == 90 { return "90 мин" }
        return "\(minutes) мин"
    }
}

private let purpleLight = Color(red: 0.65, green: 0.48, blue: 0.98)

import SwiftUI

private let purple = Color(red: 0.49, green: 0.23, blue: 0.93)
private let textPrimary = Color(red: 0.89, green: 0.85, blue: 0.95)
private let textMuted = Color(red: 0.42, green: 0.42, blue: 0.54)
private let borderSubtle = Color.white.opacity(0.05)
private let purpleLight = Color(red: 0.65, green: 0.48, blue: 0.98)

/// Форма настроек без шапки - для встраивания в основной попап.
struct SettingsFormContent: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionLabel("Расписание")
                reminderIntervalRow
                standDurationRow
                autoStartSittingRow
                Divider().background(borderSubtle)
                sectionLabel("Уведомления")
                coloredIconRow
                soundRow
                launchAtLoginRow
                showNotificationButton
                Divider().background(borderSubtle)
                workingHoursRow
                Divider().background(borderSubtle)
                authorSection
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private var autoStartSittingRow: some View {
        settingsRow(
            title: "Стартовать таймер сидеть автоматически",
            subtitle: "Если выкл — после стояния таймер остановится на 00:00 и будет мигать"
        ) {
            Toggle("", isOn: $settings.autoStartSittingTimer)
                .toggleStyle(.switch)
                .tint(purple)
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
        HStack(spacing: 8) {
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
            Button(action: {
                StandUpState.shared.startTestTrayBlink()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "eye")
                        .font(.system(size: 12))
                    Text("Моргнуть")
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

    private var authorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Автор")
            Text("Валентин Панченко")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(textPrimary)
            Link("lyucean.com - Простым языком про IT", destination: URL(string: "https://lyucean.com/")!)
                .font(.system(size: 12))
                .foregroundStyle(purpleLight)
                .tint(purpleLight)
        }
        .padding(.vertical, 20)
    }
}

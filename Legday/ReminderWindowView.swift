import SwiftUI
import AppKit

private let bgDark = Color(red: 0.09, green: 0.09, blue: 0.18)
private let purple = Color(red: 0.49, green: 0.23, blue: 0.93)
private let purpleLight = Color(red: 0.65, green: 0.48, blue: 0.98)
private let textPrimary = Color(red: 0.89, green: 0.85, blue: 0.95)
private let textMuted = Color(red: 0.55, green: 0.55, blue: 0.65)

private func randomMotivation(standDuration: Int) -> String {
    let phrases: [(Int) -> String] = [
        { m in "Спина уже подала заявление. Постой \(m) мин, пока можешь." },
        { m in "Офисный планктон должен иногда всплывать. \(m) мин." },
        { m in "Твой стул уже тебя ненавидит. Встань на \(m) мин." },
        { m in "Сидение - не спорт. Встань хотя бы на \(m) мин." },
        { m in "Твой позвоночник плачет. Встань \(m) мин." },
        { m in "Человек создан для движения. Ты пока нет. \(m) мин." },
        { m in "\(m) мин постоять было бы круто." },
        { m in "Деды стояли и ты постой \(m) мин." },
        { m in "Рабочий день - не марафон сидения. Встань на \(m) мин." },
        { m in "Встань. Это бесплатно и пока без подписки." },
        { m in "\(m) минут. Никто не попросит танцевать." },
        { m in "Ты уже просидел. Теперь постой. \(m) мин." },
        { m in "Даже Debian иногда обновляется. Встань на \(m) мин." },
        { m in "Постой \(m) мин. Спина уже созрела." },
        { m in "Твои ноги существуют. Напомни им о себе. \(m) мин." },
        { m in "Встань. Исус смотрит на тебя." },
        { m in "Спина не из железа. Хотя бы \(m) мин." },
        { m in "Встань. Это не совещание, можно молча." },
        { m in "Перерыв. \(m) мин. Это пока бесплатно." },
        { m in "Постой \(m) мин. паровоз, не гудите колеса." },
        { m in "Встань на \(m) мин. блинже к звездам." },
        { m in "Движение - не только Ctrl+S. \(m) мин." },
        { m in "Офисный стул - не трон. Сойди на \(m) мин." },
        { m in "\(m) минут стоя было бы круто." },
        { m in "Твоя осанка просит помощи. Один раз можно. \(m) мин." },
        { m in "Встань. Даже кот иногда выходит погулять." },
        { m in "Человек прямоходящий. Напоминание. \(m) мин." },
        { m in "Встань и точка." },
        { m in "\(m) мин. Минимальная программа для выживания спины." },
        { m in "Встань. Креселка подождёт." },
        { m in "Разминка. \(m) мин. Без тренера и абонемента." },
        { m in "Постой \(m) мин. Я пойду попить." },
        { m in "Встань на \(m) мин. Стул отдохнёт от тебя." },
        { m in "\(m) минут. Спина не резиновая. Хотя бы." },
        { m in "Встань и разомнись." },
        { m in "Пора. \(m) мин стоя. Без смс." },
        { m in "Спина: тихий крик. Ты: встань \(m) мин." },
        { m in "Постой \(m) мин. Так думаеть легче." },
        { m in "Кровь застоялась. Разгони. \(m) минут." },
        { m in "Встань на \(m) мин." },
        { m in "Спина уже не в силах. \(m) мин." },
        { m in "Постой \(m) мин. Потом снова можно страдать." },
        { m in "Встань. Рабочий стол никуда не денется." },
        { m in "\(m) мин на ногах. Без лайков и сторис." },
        { m in "Движение. \(m) мин. Без паспорта и визы." },
    ]
    return phrases.randomElement()!(standDuration)
}

struct ReminderWindowView: View {
    let standDuration: Int
    let onStood: () -> Void
    let onPostpone: () -> Void
    let onDismiss: () -> Void
    @State private var standButtonHovered = false
    @State private var postponeButtonHovered = false
    @State private var motivationText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "figure.stand")
                    .font(.system(size: 24))
                    .foregroundStyle(purpleLight)
                Text("Legday")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(textMuted)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(purple)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            Text("Время встать!")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            
            Text(motivationText)
                .font(.system(size: 13))
                .foregroundStyle(textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 6)
            
            HStack(spacing: 12) {
                Button(action: {
                    onStood()
                    onDismiss()
                }) {
                    Text("Встал ✓")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(standButtonHovered ? purpleLight : purple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .onHover { standButtonHovered = $0 }
                
                Button(action: {
                    onPostpone()
                    onDismiss()
                }) {
                    Text("+15 мин")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(postponeButtonHovered ? purple.opacity(0.2) : Color.clear)
                        .foregroundStyle(purple)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(purple, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .onHover { postponeButtonHovered = $0 }
            }
            .padding(20)
        }
        .frame(width: 320)
        .background(bgDark)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .onAppear { motivationText = randomMotivation(standDuration: standDuration) }
    }
}

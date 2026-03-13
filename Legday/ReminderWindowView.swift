import SwiftUI
import AppKit

private let bgDark = Color(red: 0.09, green: 0.09, blue: 0.18)
private let purple = Color(red: 0.49, green: 0.23, blue: 0.93)
private let purpleLight = Color(red: 0.65, green: 0.48, blue: 0.98)
private let textPrimary = Color(red: 0.89, green: 0.85, blue: 0.95)
private let textMuted = Color(red: 0.55, green: 0.55, blue: 0.65)

struct ReminderWindowView: View {
    let standDuration: Int
    let onStood: () -> Void
    let onPostpone: () -> Void
    let onDismiss: () -> Void
    
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
                        .foregroundStyle(textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            Text("Время встать! 🧘")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            
            Text("Поработайте стоя \(standDuration) минут — спина скажет спасибо")
                .font(.system(size: 13))
                .foregroundStyle(textMuted)
                .multilineTextAlignment(.center)
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
                        .background(purple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    onPostpone()
                    onDismiss()
                }) {
                    Text("+15 мин")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.08))
                        .foregroundStyle(textPrimary)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .frame(width: 320)
        .background(bgDark)
    }
}

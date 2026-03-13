import Foundation
import UserNotifications
import AppKit

final class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    private let standCategoryId = "STAND_REMINDER"
    
    override private init() {
        super.init()
        center.delegate = self
        registerCategory()
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }
    
    private func registerCategory() {
        let stood = UNNotificationAction(identifier: "STOOD", title: "Встал ✓", options: .foreground)
        let postpone = UNNotificationAction(identifier: "POSTPONE_15", title: "+15 мин", options: [])
        let category = UNNotificationCategory(identifier: standCategoryId, actions: [stood, postpone], intentIdentifiers: [])
        center.setNotificationCategories([category])
    }
    
    func scheduleStandReminder(in seconds: Int, standDuration: Int, sound: Bool) {
        center.removePendingNotificationRequests(withIdentifiers: ["standReminder"])
        let content = UNMutableNotificationContent()
        content.title = "Время встать! 🧘"
        content.body = "Поработайте стоя \(standDuration) минут — спина скажет спасибо"
        content.categoryIdentifier = standCategoryId
        content.sound = sound ? .default : nil
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "standReminder", content: content, trigger: trigger)
        center.add(request)
    }
    
    func showStandReminder(standDuration: Int, sound: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "Время встать! 🧘"
        content.body = "Поработайте стоя \(standDuration) минут — спина скажет спасибо"
        content.categoryIdentifier = standCategoryId
        content.sound = sound ? .default : nil
        let request = UNNotificationRequest(identifier: "standReminderNow", content: content, trigger: nil)
        center.add(request)
    }
    
    func cancelStandReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["standReminder"])
        center.removeDeliveredNotifications(withIdentifiers: ["standReminder", "standReminderNow"])
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let state = StandUpState.shared
        switch response.actionIdentifier {
        case "STOOD":
            state.userStood()
        case "POSTPONE_15":
            state.postpone15Minutes()
        default:
            break
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge, .list])
    }
}

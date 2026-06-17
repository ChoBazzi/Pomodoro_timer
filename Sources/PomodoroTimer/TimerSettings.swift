import Foundation

struct TimerSettings: Equatable {
    var focusMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
    var focusSessionsBeforeLongBreak: Int

    static let defaults = TimerSettings(
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        focusSessionsBeforeLongBreak: 4
    )

    static func saved(defaults: UserDefaults = .standard) -> TimerSettings {
        let fallback = TimerSettings.defaults

        return TimerSettings(
            focusMinutes: positiveInt(for: "focusMinutes", defaults: defaults) ?? fallback.focusMinutes,
            shortBreakMinutes: positiveInt(for: "shortBreakMinutes", defaults: defaults) ?? fallback.shortBreakMinutes,
            longBreakMinutes: positiveInt(for: "longBreakMinutes", defaults: defaults) ?? fallback.longBreakMinutes,
            focusSessionsBeforeLongBreak: positiveInt(for: "focusSessionsBeforeLongBreak", defaults: defaults) ?? fallback.focusSessionsBeforeLongBreak
        )
    }

    func save(defaults: UserDefaults = .standard) {
        defaults.set(focusMinutes, forKey: "focusMinutes")
        defaults.set(shortBreakMinutes, forKey: "shortBreakMinutes")
        defaults.set(longBreakMinutes, forKey: "longBreakMinutes")
        defaults.set(focusSessionsBeforeLongBreak, forKey: "focusSessionsBeforeLongBreak")
    }

    private static func positiveInt(for key: String, defaults: UserDefaults) -> Int? {
        let value = defaults.integer(forKey: key)
        return value > 0 ? value : nil
    }
}

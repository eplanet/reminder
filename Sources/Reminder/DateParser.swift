import Foundation

struct DateParser {
    /// Parses a free-form time string into a Date.
    /// Supports relative times like "in 2h", "in 30m", "in 1 day"
    /// and absolute times via NSDataDetector like "tomorrow at 9am", "next Monday at 10am".
    static func parse(_ input: String) -> Date? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        if let date = parseRelative(trimmed) {
            return date
        }
        if let date = parseWithDataDetector(trimmed) {
            return date
        }
        return nil
    }

    // MARK: - Relative time parsing

    private static func parseRelative(_ input: String) -> Date? {
        let lowered = input.lowercased()

        // Match patterns like "in 2h", "in 30m", "in 1d", "in 2 hours", "in 30 minutes", "in 1 day"
        let pattern = #"^in\s+(\d+)\s*(s|sec|secs|second|seconds|m|min|mins|minute|minutes|h|hr|hrs|hour|hours|d|day|days|w|week|weeks)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(lowered.startIndex..., in: lowered)
        guard let match = regex.firstMatch(in: lowered, range: range) else {
            return nil
        }

        guard let valueRange = Range(match.range(at: 1), in: lowered),
              let unitRange = Range(match.range(at: 2), in: lowered),
              let value = Double(lowered[valueRange]) else {
            return nil
        }

        let unit = String(lowered[unitRange])
        let seconds: Double
        switch unit {
        case "s", "sec", "secs", "second", "seconds":
            seconds = value
        case "m", "min", "mins", "minute", "minutes":
            seconds = value * 60
        case "h", "hr", "hrs", "hour", "hours":
            seconds = value * 3600
        case "d", "day", "days":
            seconds = value * 86400
        case "w", "week", "weeks":
            seconds = value * 604800
        default:
            return nil
        }

        return Date().addingTimeInterval(seconds)
    }

    // MARK: - NSDataDetector-based parsing

    private static func parseWithDataDetector(_ input: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        let range = NSRange(input.startIndex..., in: input)
        let matches = detector.matches(in: input, range: range)

        // Return the first detected date that is in the future
        let now = Date()
        for match in matches {
            if let date = match.date, date > now {
                return date
            }
        }

        // If we got a date but it's in the past, still return it (user might know what they're doing)
        return matches.first?.date
    }
}

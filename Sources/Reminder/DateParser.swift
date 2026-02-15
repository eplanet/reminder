import Foundation

struct ParsedReminder {
    let note: String
    let date: Date
}

struct DateParser {
    /// Parses a combined input like "Buy groceries tomorrow at 9am" or "Call mom in 2h".
    /// Returns the extracted note and the parsed date, or nil if no time expression is found.
    static func parse(_ input: String) -> ParsedReminder? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Try relative time at the end: "... in 2h"
        if let result = extractRelative(from: trimmed) {
            return result
        }

        // Try NSDataDetector to find a date expression and split it from the note
        if let result = extractWithDataDetector(from: trimmed) {
            return result
        }

        return nil
    }

    // MARK: - Relative time extraction

    private static let relativePattern = #"(^|\s)(in\s+\d+\s*(?:s|sec|secs|second|seconds|m|min|mins|minute|minutes|h|hr|hrs|hour|hours|d|day|days|w|week|weeks))\s*$"#

    private static func extractRelative(from input: String) -> ParsedReminder? {
        guard let regex = try? NSRegularExpression(pattern: relativePattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(input.startIndex..., in: input)
        guard let match = regex.firstMatch(in: input, range: range),
              let timeRange = Range(match.range(at: 2), in: input) else {
            return nil
        }

        let timeString = String(input[timeRange])
        guard let date = parseRelativeTime(timeString) else { return nil }

        let note = input[input.startIndex..<timeRange.lowerBound]
            .trimmingCharacters(in: .whitespaces)

        return ParsedReminder(note: note, date: date)
    }

    private static func parseRelativeTime(_ input: String) -> Date? {
        let lowered = input.lowercased()
        let pattern = #"^in\s+(\d+)\s*(s|sec|secs|second|seconds|m|min|mins|minute|minutes|h|hr|hrs|hour|hours|d|day|days|w|week|weeks)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(lowered.startIndex..., in: lowered)
        guard let match = regex.firstMatch(in: lowered, range: range),
              let valueRange = Range(match.range(at: 1), in: lowered),
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

    // MARK: - NSDataDetector-based extraction

    private static func extractWithDataDetector(from input: String) -> ParsedReminder? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        let nsRange = NSRange(input.startIndex..., in: input)
        let matches = detector.matches(in: input, range: nsRange)
        guard !matches.isEmpty else { return nil }

        // Pick the last match (time expression is typically at the end)
        let now = Date()
        let match = matches.last { m in
            if let d = m.date, d > now { return true }
            return false
        } ?? matches.last!

        guard let date = match.date else { return nil }
        guard let matchRange = Range(match.range, in: input) else { return nil }

        let note = input[input.startIndex..<matchRange.lowerBound]
            .trimmingCharacters(in: .whitespaces)

        return ParsedReminder(note: note, date: date)
    }
}

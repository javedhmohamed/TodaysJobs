import Foundation

/// One job assigned to the technician, decoded from `jobs.json`.
///
/// The JSON is used exactly as given, so every field that can be missing,
/// `null` or empty in the sample data is modelled as optional and cleaned up
/// by the `display…` helpers below rather than at decode time.
struct Job: Identifiable, Equatable, Decodable {
    let id: String
    /// `null` for J-103.
    let customerName: String?
    /// Empty string for J-105. Optional so a missing key can't crash decoding.
    let address: String?
    /// Parsed from `"yyyy-MM-dd HH:mm"` in the device's time zone.
    let scheduledAt: Date
    var status: JobStatus
    /// Key is absent for J-102 and empty for J-103.
    let notes: String?
}

// MARK: - Display helpers

extension Job {
    /// Customer name, or `nil` when it is missing or blank.
    var displayName: String? { customerName.nonBlank }

    /// Address, or `nil` when it is missing or blank.
    var displayAddress: String? { address.nonBlank }

    /// Notes, or `nil` when they are missing or blank.
    var displayNotes: String? { notes.nonBlank }

    /// A pending job whose scheduled time has passed.
    /// `in_progress` jobs are never overdue: the technician is already on it.
    func isOverdue(at now: Date) -> Bool {
        status == .pending && scheduledAt < now
    }

    /// The state a row or pill should show, including the derived Overdue state.
    func displayStatus(at now: Date) -> JobDisplayStatus {
        switch status {
        case .pending: isOverdue(at: now) ? .overdue : .pending
        case .inProgress: .inProgress
        case .completed: .completed
        case .unknown(let raw): .unknown(raw)
        }
    }

    /// Scheduled time as 24-hour `HH:mm`, matching the design.
    var timeText: String {
        scheduledAt.formatted(Job.timeStyle)
    }

    /// Whether the search text matches the customer name or address.
    func matches(search text: String) -> Bool {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return [displayName, displayAddress]
            .compactMap { $0 }
            .contains { $0.localizedStandardContains(query) }
    }

    /// Identifies this job on this day for saved completions, e.g.
    /// `"J-101@2026-11-25 09:30"`. Same format as the JSON, so it round-trips.
    var completionKey: String {
        "\(id)@\(scheduledAt.formatted(Job.keyStyle))"
    }

    // `.autoupdatingCurrent` everywhere, matching the decoder, so display and
    // keys follow the device if its time zone changes while the app is open.
    private static let timeStyle = Date.VerbatimFormatStyle(
        format: "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
        timeZone: .autoupdatingCurrent,
        calendar: Calendar(identifier: .gregorian)
    )

    private static let keyStyle = Date.VerbatimFormatStyle(
        format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
        timeZone: .autoupdatingCurrent,
        calendar: Calendar(identifier: .gregorian)
    )
}

private extension Optional where Wrapped == String {
    /// The trimmed string, or `nil` when it is missing or only whitespace.
    var nonBlank: String? {
        guard let trimmed = self?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }
}

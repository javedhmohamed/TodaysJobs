import Foundation

/// The status stored in the JSON.
///
/// Unknown values decode to `.unknown` instead of throwing, so one unexpected
/// status from the server can't take down the whole list.
enum JobStatus: Equatable, Hashable {
    case pending
    case inProgress
    case completed
    case unknown(String)

    init(rawValue: String) {
        switch rawValue {
        case "pending": self = .pending
        case "in_progress": self = .inProgress
        case "completed": self = .completed
        default: self = .unknown(rawValue)
        }
    }
}

extension JobStatus: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }
}

/// What the UI shows. Adds `overdue`, which is derived from the time and never stored.
enum JobDisplayStatus: Equatable {
    case pending
    case inProgress
    case completed
    case overdue
    case unknown(String)

    var label: String {
        switch self {
        case .pending: "Pending"
        case .inProgress: "In progress"
        case .completed: "Completed"
        case .overdue: "Overdue"
        case .unknown(let raw):
            raw.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

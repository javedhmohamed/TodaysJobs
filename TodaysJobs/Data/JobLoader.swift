import Foundation

enum JobLoaderError: LocalizedError, Equatable {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            "The job list (\(name).json) is missing from the app."
        }
    }
}

/// Reads and decodes the bundled `jobs.json`.
enum JobLoader {
    static let defaultFileName = "jobs"

    /// Decodes jobs from raw JSON data.
    static func decode(_ data: Data) throws -> [Job] {
        try makeDecoder().decode([Job].self, from: data)
    }

    /// Loads and decodes the JSON file bundled with the app.
    static func loadBundledJobs(
        named name: String = defaultFileName,
        in bundle: Bundle = .main
    ) throws -> [Job] {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw JobLoaderError.fileNotFound(name)
        }
        return try decode(Data(contentsOf: url))
    }

    /// `customer_name` → `customerName`, and `"2026-11-25 09:30"` → `Date`.
    static func makeDecoder() -> JSONDecoder {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // fixed format, ignore user settings
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .autoupdatingCurrent              // the times are local job-site times
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }
}

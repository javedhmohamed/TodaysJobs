import Foundation
import Observation

enum JobFilter: String, CaseIterable, Identifiable {
    case all
    case pending

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "All"
        case .pending: "Pending"
        }
    }
}

/// The single source of truth for jobs. Views read from it and call
/// `markCompleted`; the list and detail screens update automatically.
@MainActor
@Observable
final class JobStore {
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    private(set) var jobs: [Job] = []
    private(set) var loadState: LoadState = .loading

    private let loader: @MainActor () throws -> [Job]
    private let completionStore: CompletionPersisting

    init(
        loader: @escaping @MainActor () throws -> [Job] = { try JobLoader.loadBundledJobs() },
        completionStore: CompletionPersisting = UserDefaultsCompletionStore()
    ) {
        self.loader = loader
        self.completionStore = completionStore
    }

    // MARK: Loading

    func load() {
        do {
            let completed = completionStore.loadCompletedIDs()
            jobs = try loader()
                .map { job in
                    var job = job
                    if completed.contains(job.id) { job.status = .completed }
                    return job
                }
                .sorted { ($0.scheduledAt, $0.id) < ($1.scheduledAt, $1.id) }
            loadState = .loaded
        } catch {
            jobs = []
            loadState = .failed(Self.message(for: error))
        }
    }

    // MARK: Reading

    func job(id: Job.ID) -> Job? {
        jobs.first { $0.id == id }
    }

    /// Jobs for the list, filtered and searched. Already sorted by time.
    func jobs(filter: JobFilter, search: String = "") -> [Job] {
        jobs.filter { job in
            (filter == .all || job.status == .pending) && job.matches(search: search)
        }
    }

    /// Jobs still to start. Includes overdue ones, matching the design's "3 pending".
    var pendingCount: Int {
        jobs.filter { $0.status == .pending }.count
    }

    /// The day the jobs are for, used in the subtitle.
    var scheduleDate: Date? {
        jobs.first?.scheduledAt
    }

    // MARK: Actions

    func markCompleted(_ id: Job.ID) {
        guard let index = jobs.firstIndex(where: { $0.id == id }),
              jobs[index].status != .completed else { return }
        jobs[index].status = .completed

        var completed = completionStore.loadCompletedIDs()
        completed.insert(id)
        completionStore.saveCompletedIDs(completed)
    }

    // MARK: Helpers

    private static func message(for error: Error) -> String {
        if let error = error as? LocalizedError, let description = error.errorDescription {
            return description
        }
        if error is DecodingError {
            return "The job list is in an unexpected format."
        }
        return error.localizedDescription
    }
}

// MARK: - Previews

extension JobStore {
    /// A store loaded with the bundled sample data and no saved completions.
    static func preview() -> JobStore {
        let store = JobStore(completionStore: InMemoryCompletionStore())
        store.load()
        return store
    }
}

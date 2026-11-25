import Foundation

/// Remembers which jobs the technician completed, so it survives an app restart.
///
/// Only the IDs are stored. The JSON stays the source of truth for everything
/// else, and completing a job is the only change the app makes.
protocol CompletionPersisting {
    func loadCompletedIDs() -> Set<Job.ID>
    func saveCompletedIDs(_ ids: Set<Job.ID>)
}

struct UserDefaultsCompletionStore: CompletionPersisting {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "completedJobIDs") {
        self.defaults = defaults
        self.key = key
    }

    func loadCompletedIDs() -> Set<Job.ID> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }

    func saveCompletedIDs(_ ids: Set<Job.ID>) {
        defaults.set(ids.sorted(), forKey: key)
    }
}

/// For previews and tests.
final class InMemoryCompletionStore: CompletionPersisting {
    private(set) var ids: Set<Job.ID>

    init(ids: Set<Job.ID> = []) {
        self.ids = ids
    }

    func loadCompletedIDs() -> Set<Job.ID> { ids }
    func saveCompletedIDs(_ ids: Set<Job.ID>) { self.ids = ids }
}

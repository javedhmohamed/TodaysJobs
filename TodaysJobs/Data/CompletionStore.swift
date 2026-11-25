import Foundation

/// Remembers which jobs the technician completed, so it survives an app restart.
///
/// Stores `Job.completionKey` values (ID + scheduled time), not bare IDs, so a
/// completion never carries over to tomorrow's job that reuses the same ID.
/// The JSON stays the source of truth for everything else.
protocol CompletionPersisting {
    func loadCompletedKeys() -> Set<String>
    func saveCompletedKeys(_ keys: Set<String>)
}

struct UserDefaultsCompletionStore: CompletionPersisting {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "completedJobKeys") {
        self.defaults = defaults
        self.key = key
    }

    func loadCompletedKeys() -> Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }

    func saveCompletedKeys(_ keys: Set<String>) {
        defaults.set(keys.sorted(), forKey: key)
    }
}

/// For previews and tests.
final class InMemoryCompletionStore: CompletionPersisting {
    private(set) var keys: Set<String>

    init(keys: Set<String> = []) {
        self.keys = keys
    }

    func loadCompletedKeys() -> Set<String> { keys }
    func saveCompletedKeys(_ keys: Set<String>) { self.keys = keys }
}

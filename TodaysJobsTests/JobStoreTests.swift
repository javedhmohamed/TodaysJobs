import XCTest
@testable import TodaysJobs

@MainActor
final class JobStoreTests: XCTestCase {

    private func makeStore(
        json: String = Fixtures.sampleJSON,
        completed: Set<String> = []
    ) -> (JobStore, InMemoryCompletionStore) {
        let persistence = InMemoryCompletionStore(keys: completed)
        let store = JobStore(
            loader: { try JobLoader.decode(Data(json.utf8)) },
            completionStore: persistence
        )
        store.load()
        return (store, persistence)
    }

    // MARK: Loading

    func testLoadSucceeds() {
        let (store, _) = makeStore()
        XCTAssertEqual(store.loadState, .loaded)
        XCTAssertEqual(store.jobs.count, 5)
    }

    func testJobsAreSortedByScheduledTime() {
        let reversed = Fixtures.jobsArray([
            Fixtures.jobObject(id: "late", scheduledAt: "2026-11-25 17:00"),
            Fixtures.jobObject(id: "early", scheduledAt: "2026-11-25 08:00"),
        ])
        let (store, _) = makeStore(json: reversed)
        XCTAssertEqual(store.jobs.map(\.id), ["early", "late"])
    }

    func testLoadFailureSetsErrorState() {
        let store = JobStore(
            loader: { throw JobLoaderError.fileNotFound("jobs") },
            completionStore: InMemoryCompletionStore()
        )
        store.load()
        XCTAssertEqual(store.jobs, [])
        guard case .failed(let message) = store.loadState else {
            return XCTFail("Expected failed state, got \(store.loadState)")
        }
        XCTAssertFalse(message.isEmpty)
    }

    // MARK: Mark completed

    func testMarkCompletedUpdatesJobAndCount() {
        let (store, _) = makeStore()
        XCTAssertEqual(store.pendingCount, 3)

        store.markCompleted("J-101")

        XCTAssertEqual(store.job(id: "J-101")?.status, .completed)
        XCTAssertEqual(store.pendingCount, 2)
        XCTAssertFalse(store.jobs(filter: .pending).contains { $0.id == "J-101" })
    }

    func testMarkCompletedPersists() {
        let (store, persistence) = makeStore()
        store.markCompleted("J-103")
        XCTAssertEqual(persistence.keys, ["J-103@2026-11-25 13:15"])
    }

    func testCompletionSurvivesRestart() {
        let (_, persistence) = makeStore(completed: ["J-105@2026-11-25 17:30"])
        // A new store with the same persistence = an app restart.
        let restarted = JobStore(
            loader: { try JobLoader.decode(Data(Fixtures.sampleJSON.utf8)) },
            completionStore: persistence
        )
        restarted.load()
        XCTAssertEqual(restarted.job(id: "J-105")?.status, .completed)
    }

    func testCompletionDoesNotCarryOverToSameIDOnAnotherDay() {
        let (today, persistence) = makeStore()
        today.markCompleted("J-101")

        // Tomorrow's list reuses the ID J-101 for a different job.
        let tomorrowJSON = Fixtures.jobsArray([
            Fixtures.jobObject(id: "J-101", scheduledAt: "2026-11-26 09:30"),
        ])
        let tomorrow = JobStore(
            loader: { try JobLoader.decode(Data(tomorrowJSON.utf8)) },
            completionStore: persistence
        )
        tomorrow.load()

        XCTAssertEqual(tomorrow.job(id: "J-101")?.status, .pending)
    }

    func testUndoWorksAfterRestart() {
        let (_, persistence) = makeStore(completed: ["J-101@2026-11-25 09:30"])
        let restarted = JobStore(
            loader: { try JobLoader.decode(Data(Fixtures.sampleJSON.utf8)) },
            completionStore: persistence
        )
        restarted.load()

        XCTAssertTrue(restarted.canReopen("J-101"))
        restarted.reopen("J-101")
        XCTAssertEqual(restarted.job(id: "J-101")?.status, .pending)
        XCTAssertTrue(persistence.keys.isEmpty)
    }

    func testCompletionKeyMatchesJSONFormat() {
        let (store, _) = makeStore()
        XCTAssertEqual(store.job(id: "J-101")?.completionKey, "J-101@2026-11-25 09:30")
    }

    func testDuplicateIDsKeepFirstJob() {
        let json = Fixtures.jobsArray([
            Fixtures.jobObject(id: "dup", scheduledAt: "2026-11-25 08:00", status: "pending"),
            Fixtures.jobObject(id: "dup", scheduledAt: "2026-11-25 09:00", status: "completed"),
        ])
        let (store, _) = makeStore(json: json)
        XCTAssertEqual(store.jobs.count, 1)
        XCTAssertEqual(store.job(id: "dup")?.status, .pending)
    }

    // MARK: Undo

    func testReopenRestoresOriginalStatusAndPersistence() {
        let (store, persistence) = makeStore()
        store.markCompleted("J-102") // was in_progress
        XCTAssertTrue(store.canReopen("J-102"))

        store.reopen("J-102")

        XCTAssertEqual(store.job(id: "J-102")?.status, .inProgress)
        XCTAssertTrue(persistence.keys.isEmpty)
    }

    func testCannotReopenJobCompletedInJSON() {
        let (store, _) = makeStore()
        XCTAssertFalse(store.canReopen("J-104"))
        store.reopen("J-104")
        XCTAssertEqual(store.job(id: "J-104")?.status, .completed)
    }

    func testCannotReopenJobThatIsNotCompleted() {
        let (store, _) = makeStore()
        XCTAssertFalse(store.canReopen("J-101"))
    }

    // MARK: Filter and search

    func testPendingFilterShowsOnlyPendingJobs() {
        let (store, _) = makeStore()
        XCTAssertEqual(store.jobs(filter: .pending).map(\.id), ["J-101", "J-103", "J-105"])
        XCTAssertEqual(store.jobs(filter: .all).count, 5)
    }

    func testSearchMatchesNameAndAddressCaseInsensitively() {
        let (store, _) = makeStore()
        XCTAssertEqual(store.jobs(filter: .all, search: "priya").map(\.id), ["J-102"])
        XCTAssertEqual(store.jobs(filter: .all, search: "ADYAR").map(\.id), ["J-103"])
        XCTAssertEqual(store.jobs(filter: .all, search: "  ").count, 5)
        XCTAssertTrue(store.jobs(filter: .all, search: "zzz").isEmpty)
    }

    // MARK: Overdue

    func testOverdueRule() throws {
        let (store, _) = makeStore()
        let ravi = try XCTUnwrap(store.job(id: "J-101"))      // pending 09:30
        let priya = try XCTUnwrap(store.job(id: "J-102"))     // in progress 11:00
        let karthik = try XCTUnwrap(store.job(id: "J-104"))   // completed 15:45
        let later = ravi.scheduledAt.addingTimeInterval(24 * 60 * 60)

        XCTAssertEqual(ravi.displayStatus(at: ravi.scheduledAt.addingTimeInterval(-60)), .pending)
        XCTAssertEqual(ravi.displayStatus(at: ravi.scheduledAt.addingTimeInterval(60)), .overdue)
        XCTAssertEqual(priya.displayStatus(at: later), .inProgress)
        XCTAssertEqual(karthik.displayStatus(at: later), .completed)
    }

    func testCompletingOverdueJobClearsOverdue() throws {
        let (store, _) = makeStore()
        let later = try XCTUnwrap(store.job(id: "J-101")).scheduledAt.addingTimeInterval(3600)
        store.markCompleted("J-101")
        XCTAssertEqual(store.job(id: "J-101")?.displayStatus(at: later), .completed)
    }
}

import XCTest
@testable import TodaysJobs

/// Decoding the sample JSON exactly as given, including every edge case it contains.
@MainActor // safe under Xcode 26's default MainActor isolation as well
final class JobDecodingTests: XCTestCase {

    private func decodeSample() throws -> [Job] {
        try JobLoader.decode(Data(Fixtures.sampleJSON.utf8))
    }

    private func job(_ id: String, in jobs: [Job]) throws -> Job {
        try XCTUnwrap(jobs.first { $0.id == id }, "Missing \(id)")
    }

    func testDecodesAllFiveJobs() throws {
        let jobs = try decodeSample()
        XCTAssertEqual(jobs.map(\.id), ["J-101", "J-102", "J-103", "J-104", "J-105"])
    }

    func testBundledFileDecodes() throws {
        let jobs = try JobLoader.loadBundledJobs(in: Bundle(for: JobStore.self))
        XCTAssertEqual(jobs.count, 5)
    }

    func testSnakeCaseKeysMapToProperties() throws {
        let ravi = try job("J-101", in: decodeSample())
        XCTAssertEqual(ravi.customerName, "Ravi Kumar")
        XCTAssertEqual(ravi.address, "12 2nd Avenue, Anna Nagar, Chennai")
    }

    func testParsesScheduledAtInLocalTime() throws {
        let ravi = try job("J-101", in: decodeSample())
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: ravi.scheduledAt)
        XCTAssertEqual(parts.year, 2026)
        XCTAssertEqual(parts.month, 11)
        XCTAssertEqual(parts.day, 25)
        XCTAssertEqual(parts.hour, 9)
        XCTAssertEqual(parts.minute, 30)
        XCTAssertEqual(ravi.timeText, "09:30")
    }

    func testMapsAllStatuses() throws {
        let jobs = try decodeSample()
        XCTAssertEqual(try job("J-101", in: jobs).status, .pending)
        XCTAssertEqual(try job("J-102", in: jobs).status, .inProgress)
        XCTAssertEqual(try job("J-104", in: jobs).status, .completed)
    }

    func testNullCustomerNameShowsAsMissing() throws {
        let job = try job("J-103", in: decodeSample())
        XCTAssertNil(job.customerName)
        XCTAssertNil(job.displayName)
    }

    func testMissingNotesKeyDecodesAsNil() throws {
        let job = try job("J-102", in: decodeSample())
        XCTAssertNil(job.notes)
        XCTAssertNil(job.displayNotes)
    }

    func testEmptyNotesShowAsMissing() throws {
        let job = try job("J-103", in: decodeSample())
        XCTAssertEqual(job.notes, "")
        XCTAssertNil(job.displayNotes)
    }

    func testEmptyAddressShowsAsMissing() throws {
        let job = try job("J-105", in: decodeSample())
        XCTAssertEqual(job.address, "")
        XCTAssertNil(job.displayAddress)
    }

    func testUnknownStatusDoesNotThrow() throws {
        let json = Fixtures.job(status: "on_hold")
        let jobs = try JobLoader.decode(Data(json.utf8))
        XCTAssertEqual(jobs.first?.status, .unknown("on_hold"))
        XCTAssertEqual(jobs.first?.displayStatus(at: .now).label, "On Hold")
    }

    func testMalformedDateThrows() {
        let json = Fixtures.job(scheduledAt: "25/11/2026 9:30am")
        XCTAssertThrowsError(try JobLoader.decode(Data(json.utf8)))
    }
}

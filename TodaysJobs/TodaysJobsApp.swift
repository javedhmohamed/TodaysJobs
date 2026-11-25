import SwiftUI

@main
struct TodaysJobsApp: App {
    @State private var store = JobStore()

    var body: some Scene {
        WindowGroup {
            JobListView()
                .environment(store)
        }
    }
}

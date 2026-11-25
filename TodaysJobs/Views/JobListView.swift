import SwiftUI

struct JobListView: View {
    @Environment(JobStore.self) private var store
    @State private var filter: JobFilter = .all
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            // Re-render every minute so jobs turn Overdue without a relaunch.
            TimelineView(.everyMinute) { context in
                content(now: context.date)
            }
            .navigationTitle("Today's Jobs")
            .navigationDestination(for: Job.ID.self) { id in
                JobDetailView(jobID: id)
            }
            .searchable(text: $searchText, prompt: "Customer or address")
        }
        .task {
            if store.loadState == .loading { store.load() }
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        switch store.loadState {
        case .loading:
            ProgressView("Loading jobs…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't Load Jobs", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { store.load() }
                    .buttonStyle(.borderedProminent)
            }

        case .loaded:
            jobList(now: now)
        }
    }

    private func jobList(now: Date) -> some View {
        let rows = store.jobs(filter: filter, search: searchText)

        return List {
            Section {
                ForEach(rows) { job in
                    NavigationLink(value: job.id) {
                        JobRow(job: job, now: now)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 } // hairline inset 16 pt
                }
            } header: {
                header
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: rows.map(\.id))
        .overlay {
            if rows.isEmpty { emptyState }
        }
    }

    /// Subtitle and the All / Pending control, under the large title.
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)

            Picker("Show", selection: $filter) {
                ForEach(JobFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
        .textCase(nil)
        .padding(.bottom, 8)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }

    /// "Wednesday, 25 November · 3 pending"
    private var subtitle: String {
        let day = (store.scheduleDate ?? .now)
            .formatted(.dateTime.weekday(.wide).day().month(.wide))
        return "\(day) · \(store.pendingCount) pending"
    }

    @ViewBuilder
    private var emptyState: some View {
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if filter == .pending && !store.jobs.isEmpty {
            ContentUnavailableView {
                Label("All Caught Up", systemImage: "checkmark.circle")
            } description: {
                Text("No pending jobs left for today.")
            } actions: {
                Button("Show All Jobs") { filter = .all }
            }
        } else {
            ContentUnavailableView(
                "No Jobs Today",
                systemImage: "calendar",
                description: Text("Jobs assigned to you will show up here.")
            )
        }
    }
}

#Preview {
    JobListView()
        .environment(JobStore.preview())
}

#Preview("Load error") {
    let store = JobStore(
        loader: { throw JobLoaderError.fileNotFound("jobs") },
        completionStore: InMemoryCompletionStore()
    )
    store.load()
    return JobListView().environment(store)
}

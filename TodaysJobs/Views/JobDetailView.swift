import SwiftUI

/// Built for a technician at the customer's door: who and what first, then
/// when, where (with directions) and the notes, with the main action in
/// thumb reach at the bottom.
struct JobDetailView: View {
    @Environment(JobStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var isConfirmingCompletion = false

    let jobID: Job.ID

    var body: some View {
        if let job = store.job(id: jobID) {
            TimelineView(.everyMinute) { context in
                detail(for: job, now: context.date)
            }
            .navigationTitle(job.id)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) { completionBar(for: job) }
            .sensoryFeedback(.success, trigger: job.status) { _, new in new == .completed }
        } else {
            ContentUnavailableView(
                "Job Not Found",
                systemImage: "questionmark.folder",
                description: Text("This job is no longer in today's list.")
            )
        }
    }

    // MARK: Sections

    private func detail(for job: Job, now: Date) -> some View {
        let status = job.displayStatus(at: now)

        return List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    StatusPill(status: status)
                    if let name = job.displayName {
                        Text(name).font(.title2.bold())
                    } else {
                        Text("Unknown customer")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Schedule") {
                LabeledContent {
                    Text(job.timeText)
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(status == .overdue ? JobDisplayStatus.overdue.textColor : .primary)
                } label: {
                    Label(
                        job.scheduledAt.formatted(.dateTime.weekday(.wide).day().month(.wide)),
                        systemImage: "clock"
                    )
                }

                if status == .overdue {
                    Label(lateText(for: job, now: now), systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(JobDisplayStatus.overdue.textColor)
                }
            }

            Section("Address") {
                if let address = job.displayAddress {
                    Text(address)
                        .textSelection(.enabled)
                    Button {
                        if let url = directionsURL(to: address) { openURL(url) }
                    } label: {
                        Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    }
                } else {
                    Label("No address yet", systemImage: "mappin.slash")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Notes") {
                if let notes = job.displayNotes {
                    Text(notes).textSelection(.enabled)
                } else {
                    Text("No notes for this job.")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                LabeledContent("Job ID", value: job.id)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: Completion

    @ViewBuilder
    private func completionBar(for job: Job) -> some View {
        Group {
            if job.status == .completed {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(JobDisplayStatus.completed.textColor)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(JobDisplayStatus.completed.fillColor, in: Capsule())
                    .accessibilityAddTraits(.isStaticText)
            } else {
                Button {
                    isConfirmingCompletion = true
                } label: {
                    Label("Mark as Completed", systemImage: "checkmark.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                // Completing can't be undone in this version, so confirm first.
                .confirmationDialog(
                    "Mark this job as completed?",
                    isPresented: $isConfirmingCompletion,
                    titleVisibility: .visible
                ) {
                    Button("Mark as Completed") {
                        withAnimation { store.markCompleted(job.id) }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.bar)
    }

    // MARK: Helpers

    private func lateText(for job: Job, now: Date) -> String {
        let seconds = max(60, Int(now.timeIntervalSince(job.scheduledAt)))
        let late = Duration.seconds(seconds)
            .formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated, maximumUnitCount: 2))
        return "\(late) past scheduled time"
    }

    private func directionsURL(to address: String) -> URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [URLQueryItem(name: "daddr", value: address)]
        return components?.url
    }
}

#Preview("Overdue (J-101)") {
    NavigationStack {
        JobDetailView(jobID: "J-101")
    }
    .environment(JobStore.preview())
}

#Preview("No address (J-105)") {
    NavigationStack {
        JobDetailView(jobID: "J-105")
    }
    .environment(JobStore.preview())
}

import SwiftUI
import UIKit

/// Built for a technician at the customer's door. Reading order follows the
/// visit: who → when → what to do (notes) → where. The one action that
/// matters, Mark as Completed, sits at the bottom within thumb reach.
struct JobDetailView: View {
    @Environment(JobStore.self) private var store
    @Environment(\.openURL) private var openURL

    let jobID: Job.ID

    var body: some View {
        if let job = store.job(id: jobID) {
            TimelineView(.everyMinute) { context in
                detail(for: job, now: context.date)
            }
            .navigationTitle("Job \(job.id)")
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
            // Who
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if let name = job.displayName {
                        Text(name)
                            .font(.title2.bold())
                    } else {
                        Text("Unknown customer")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    StatusPill(status: status)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 4, trailing: 4))
                .listRowBackground(Color.clear)
                .accessibilityElement(children: .combine)
            }

            // When
            Section {
                LabeledContent {
                    Text(job.timeText)
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(status == .overdue ? JobDisplayStatus.overdue.textColor : .primary)
                } label: {
                    Label(dayText(for: job, now: now), systemImage: "clock")
                }

                if status == .overdue {
                    Label(lateText(for: job, now: now), systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(JobDisplayStatus.overdue.textColor)
                }
            }

            // What to do
            Section("Notes") {
                if let notes = job.displayNotes {
                    Text(notes)
                        .textSelection(.enabled)
                } else {
                    Text("No notes")
                        .foregroundStyle(.secondary)
                }
            }

            // Where
            Section {
                if let address = job.displayAddress {
                    Text(address)
                        .textSelection(.enabled)
                        .contextMenu {
                            Button("Copy Address", systemImage: "doc.on.doc") {
                                UIPasteboard.general.string = address
                            }
                        }
                    Button {
                        if let url = directionsURL(to: address) { openURL(url) }
                    } label: {
                        Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    }
                } else {
                    Label("No address yet", systemImage: "mappin.slash")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Address")
            } footer: {
                if job.displayAddress == nil {
                    Text("Directions will be available once an address is added.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
    }

    // MARK: Completion

    /// Completing is one tap with a success haptic, not a confirmation
    /// dialog: it's the most frequent action, and Undo covers mistakes.
    private func completionBar(for job: Job) -> some View {
        Group {
            if job.status == .completed {
                HStack(spacing: 12) {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(JobDisplayStatus.completed.textColor)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(JobDisplayStatus.completed.fillColor, in: Capsule())

                    if store.canReopen(job.id) {
                        Button("Undo") {
                            withAnimation { store.reopen(job.id) }
                        }
                        .font(.headline)
                        .frame(minWidth: 44, minHeight: 50)
                        .accessibilityHint("Marks this job as not completed")
                    }
                }
            } else {
                Button {
                    withAnimation { store.markCompleted(job.id) }
                } label: {
                    Label("Mark as Completed", systemImage: "checkmark.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: Helpers

    /// "Today" for today's jobs; the full date otherwise.
    private func dayText(for job: Job, now: Date) -> String {
        Calendar.current.isDate(job.scheduledAt, inSameDayAs: now)
            ? "Today"
            : job.scheduledAt.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    /// "45 min late", "2 hr 10 min late", "1 day 3 hr late".
    private func lateText(for job: Job, now: Date) -> String {
        let seconds = max(60, Int(now.timeIntervalSince(job.scheduledAt)))
        let late = Duration.seconds(seconds)
            .formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated, maximumUnitCount: 2))
        return "\(late) late"
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

import SwiftUI

/// One row in the list. Covers all six designed states:
/// pending, in progress, completed, overdue, missing name, missing address.
struct JobRow: View {
    let job: Job
    let now: Date

    private var status: JobDisplayStatus { job.displayStatus(at: now) }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                name
                address
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                time
                StatusPill(status: status)
            }
        }
        .frame(minHeight: 48) // + 12 pt top/bottom insets = 72 pt row
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens job details")
    }

    // 17 pt semibold, primary. Missing → "Unknown customer", secondary, regular.
    @ViewBuilder private var name: some View {
        if let name = job.displayName {
            Text(name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
        } else {
            Text("Unknown customer")
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // 15 pt regular, secondary, one line, truncated at the end.
    @ViewBuilder private var address: some View {
        HStack(spacing: 4) {
            Image(systemName: job.displayAddress == nil ? "mappin.slash" : "mappin.and.ellipse")
                .font(.caption)
                .accessibilityHidden(true)
            Text(job.displayAddress ?? "No address yet")
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    // 15 pt medium, monospaced digits. Overdue: red + semibold. Completed: secondary.
    private var time: some View {
        Text(job.timeText)
            .font(.subheadline.weight(status == .overdue ? .semibold : .medium))
            .monospacedDigit()
            .foregroundStyle(timeColor)
            .accessibilityLabel("Scheduled at \(job.timeText)")
    }

    private var timeColor: Color {
        switch status {
        case .overdue: JobDisplayStatus.overdue.textColor
        case .completed: .secondary
        default: .primary
        }
    }
}

#Preview {
    let store = JobStore.preview()
    return List {
        ForEach(store.jobs) { job in
            JobRow(job: job, now: job.scheduledAt.addingTimeInterval(-60))
        }
    }
    .listStyle(.insetGrouped)
}

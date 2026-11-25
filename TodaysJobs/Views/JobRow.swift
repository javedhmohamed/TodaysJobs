import SwiftUI

/// One row in the list. Covers all six designed states:
/// pending, in progress, completed, overdue, missing name, missing address.
struct JobRow: View {
    let job: Job
    let now: Date

    @Environment(\.dynamicTypeSize) private var typeSize

    private var status: JobDisplayStatus { job.displayStatus(at: now) }
    private var isLargeType: Bool { typeSize.isAccessibilitySize }

    var body: some View {
        Group {
            if isLargeType {
                // At accessibility sizes two columns would crush the name, so stack.
                VStack(alignment: .leading, spacing: 6) {
                    name
                    address
                    HStack(spacing: 8) {
                        time
                        StatusPill(status: status)
                    }
                }
            } else {
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
            }
        }
        .frame(minHeight: 48) // + 12 pt top/bottom insets = 72 pt row
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    // 17 pt semibold, primary. Missing → "Unknown customer", secondary, regular.
    @ViewBuilder private var name: some View {
        if let name = job.displayName {
            Text(name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(isLargeType ? 3 : 1)
        } else {
            Text("Unknown customer")
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(isLargeType ? 3 : 1)
        }
    }

    // 15 pt regular, secondary, one line, truncated at the end.
    private var address: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: job.displayAddress == nil ? "mappin.slash" : "mappin.and.ellipse")
                .font(.caption)
            Text(job.displayAddress ?? "No address yet")
                .lineLimit(isLargeType ? 4 : 1)
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
    }

    private var timeColor: Color {
        switch status {
        case .overdue: JobDisplayStatus.overdue.textColor
        case .completed: .secondary
        default: .primary
        }
    }

    /// Status is read early so a VoiceOver user hears "Overdue" before the address.
    private var accessibilityText: String {
        [
            job.displayName ?? "Unknown customer",
            status.label,
            job.timeText,
            job.displayAddress ?? "No address yet",
        ].joined(separator: ", ")
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

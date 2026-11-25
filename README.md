# Today's Jobs

A SwiftUI app that shows a field technician the jobs assigned to them today. They can open a job to see its details and mark it Completed when the work is done.

Built for the Zuper iOS Intern Assignment (Round 1).

## Quick start

1. Open `TodaysJobs.xcodeproj` in Xcode 16 or later.
2. Choose any iPhone simulator running iOS 17 or later.
3. Press **⌘R** to run, or **⌘U** to run the tests.

There are no third-party dependencies and no setup steps.

## Features

| Requirement | Status |
|---|---|
| Load jobs from the bundled `jobs.json` (unchanged) | ✅ |
| List shows customer name, address, time and status | ✅ |
| Detail screen with all fields, including notes | ✅ |
| Mark as Completed from the detail screen, and the list updates | ✅ |
| Filter to pending jobs (All / Pending) | ✅ |
| **Bonus:** sorted by scheduled time | ✅ |
| **Bonus:** completed status survives an app restart (`UserDefaults`) | ✅ |
| **Bonus:** search by customer name or address | ✅ |
| **Bonus:** unit tests for decoding and store logic | ✅ |
| **Bonus:** empty, no-results and load-error states | ✅ |

The list covers all six row states from the design: pending, in progress, completed, overdue, missing customer name and missing address.

## Project structure

```
TodaysJobs/
├── TodaysJobsApp.swift        App entry; creates the JobStore
├── Models/
│   ├── Job.swift              Decodable model and display helpers
│   └── JobStatus.swift        Stored status and display status (adds Overdue)
├── Data/
│   ├── JobLoader.swift        Bundle loading and the JSON decoder setup
│   ├── JobStore.swift         @Observable source of truth: load, filter, complete
│   └── CompletionStore.swift  Persists completed job IDs
├── Views/
│   ├── JobListView.swift      List, filter, search, empty and error states
│   ├── JobRow.swift           One row, every designed state
│   ├── StatusPill.swift       Capsule status label and colours
│   └── JobDetailView.swift    Detail screen and the Mark as Completed action
└── Resources/jobs.json        Sample data, exactly as provided
TodaysJobsTests/               XCTest unit tests and the JSON fixture
```

## Design decisions

**Data**
- The JSON is decoded exactly as given. `customer_name`, `notes` and `address` are optional, and blank strings are treated the same as missing in the `display…` helpers. That covers the `null` name in J-103, the missing `notes` key in J-102, the empty notes in J-103 and the empty address in J-105.
- `scheduled_at` uses a fixed `yyyy-MM-dd HH:mm` formatter (`en_US_POSIX`, device time zone), because it isn't ISO 8601.
- An unknown `status` decodes to `.unknown` instead of failing, so one bad value can't empty the whole list.
- **Overdue** is calculated, never stored: a `pending` job whose time has passed. In-progress jobs are never overdue. The list re-renders every minute (`TimelineView`), so a job turns Overdue without a relaunch.
- **Pending** means `status == pending`, overdue jobs included. This matches the "3 pending" count in the design.

**Architecture**
- There is one `@Observable` `JobStore` injected with `.environment`. The detail screen calls `markCompleted`, and the list updates because both read the same store.
- The loader and the persistence are injected, so tests and previews run without the bundle or `UserDefaults`.
- Only the IDs of completed jobs are saved. The JSON stays the source of truth for everything else.

**Detail screen**

The detail screen is designed for a technician standing at the customer's door:
- Status and name at the top.
- The time, with a "past scheduled time" warning if the job is late.
- The address, with **Get Directions** (Apple Maps), or "No address yet" if there isn't one.
- The notes, or "No notes for this job."
- A large **Mark as Completed** button at the bottom, within thumb reach. It asks for confirmation because this version can't undo a completion, and plays a success haptic.

**Accessibility**
- Text styles (`.headline`, `.subheadline`, `.caption`) match the design's 17/15/12 pt sizes and also scale with Dynamic Type.
- Pill colours are darker or lighter than the system colours so the text passes 4.5:1 contrast, in both light and dark mode.
- Status is always written out as text, never shown by colour alone.
- Each row reads as one VoiceOver element.

## Assumptions

- All sample jobs are on 25 Nov 2026. The subtitle shows the date of the jobs, not today's date. On any later day, every pending job shows as Overdue, which is the correct result of the rule.
- Times are shown in 24-hour `HH:mm` format to match the design.
- A completed job can't be reopened. Nothing in the requirements asked for undo.

## Tests

Run them with **⌘U**. They cover:
- **Decoding:** all 5 jobs, snake_case keys, local date parsing, every status, the null name, the missing notes key, empty notes, the empty address, an unknown status, and a malformed date (should throw).
- **Store:** sorting, the load-failure state, mark completed (status, count, filter), persistence across a simulated restart, an unknown ID, the pending filter, search, and the overdue rule.

## AI tools used

- Claude Code: <!-- add share link / exported session file, e.g. claude-session.md -->

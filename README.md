# Today's Jobs

A SwiftUI app that shows a field technician the jobs assigned to them today. They can open a job to see its details and mark it Completed when the work is done.

## javedhFinal is the folder 

  
🚩🚩🚩 ##   

## imortant notice the given system is 26.4.1 and the requirements is ios 17 or later the mac need to be updated to the latest version to download the latest verion of xcode and then the xcode iphone simulation tool inthe latest vesion therefore i made it and tested it in my mac and will attach screenshots as proof (the updation of the system and the too will take more than the given time)         


##

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
│   └── CompletionStore.swift  Persists completed jobs (ID + scheduled time)
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
- Each completed job is saved as its ID plus its scheduled time (`J-101@2026-11-25 09:30`), not the ID alone, so a completion never carries over to a job with the same ID on a different day. The JSON stays the source of truth for everything else.
- Duplicate IDs in the JSON are removed when loading, keeping the first occurrence.

**Detail screen**

The detail screen is designed for a technician standing at the customer's door. Its reading order follows the visit: who, then when, then what to do, then where.
- The name comes first, with the status pill under it.
- **When:** "Today, 09:30", with "45 min late" if the job is overdue. It doesn't repeat the weekday on a screen that's already about today.
- **Notes** come before the address, because they hold instructions such as "call before arrival". If there are none, it says "No notes".
- **Address:** a **Get Directions** button (Apple Maps), and a long-press to copy the address. If there's no address: "No address yet", plus a footer explaining that directions will appear once an address is added.
- **Mark as Completed** is one tap at the bottom, within thumb reach, with a success haptic. There's no confirmation dialog, because this is the action a technician repeats most. **Undo** covers mistakes and restores the original status from the JSON. Jobs that arrive already completed can't be reopened.

**UX copy**
- Error messages say what happened and what to do next, with no file names or other technical detail. The technical reason is kept in `loadState` for debugging.
- Empty states describe the actual situation, for example "Every job today is in progress or completed", and offer a way out with **Show All Jobs**.
- Terms are the same everywhere: "No address yet" appears on both the row and the detail screen.

**Accessibility**
- Text styles match the design's 17/15/12 pt sizes and also scale with Dynamic Type. At accessibility text sizes the row switches from two columns to a vertical stack, and lines wrap instead of collapsing the name to "R…".
- VoiceOver reads each row as one element, with the status second: "Ravi Kumar, Overdue, 09:30, 12 2nd Avenue…".
- Pill colours are darker or lighter than the system colours so the text passes 4.5:1 contrast, in both light and dark mode. Status is always written out as text, never shown by colour alone.
- Known gap: the system `secondaryLabel` colour, which the design requires, is about 3.4:1 on white. The iOS Increase Contrast setting raises it.
- All tap targets are at least 44 pt.

## Assumptions

- All sample jobs are on 25 Nov 2026. The subtitle shows the date of the jobs, not today's date. On any later day, every pending job shows as Overdue, which is the correct result of the rule.
- Times are shown in 24-hour `HH:mm` format to match the design.
- Undo restores the status from the JSON, even after a restart. Completing a job is saved immediately.

## Tests

Run them with **⌘U**. They cover:
- **Decoding:** all 5 jobs, snake_case keys, local date parsing, every status, the null name, the missing notes key, empty notes, the empty address, an unknown status, and a malformed date (should throw).
- **Store:** sorting, the load-failure state, mark completed (status, count, filter), undo (restores the original status and clears the saved completion; not allowed for jobs completed in the JSON), persistence across a simulated restart, undo after a restart, no carry-over to the same ID on another day, duplicate IDs, the completion key format, an unknown ID, the pending filter, search, and the overdue rule.

## tools used

- Claude Code: <!-- add share link / exported session file, e.g. claude-session.md -->
- And ME :)

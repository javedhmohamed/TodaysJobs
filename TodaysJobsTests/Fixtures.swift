import Foundation

enum Fixtures {
    /// Byte-for-byte the same content as `jobs.json` from the assignment.
    static let sampleJSON = """
    [
      {
        "id": "J-101",
        "customer_name": "Ravi Kumar",
        "address": "12 2nd Avenue, Anna Nagar, Chennai",
        "scheduled_at": "2026-11-25 09:30",
        "status": "pending",
        "notes": "Roof leak near the chimney. Customer prefers a call before arrival."
      },
      {
        "id": "J-102",
        "customer_name": "Priya S",
        "address": "45 Usman Road, T Nagar, Chennai",
        "scheduled_at": "2026-11-25 11:00",
        "status": "in_progress"
      },
      {
        "id": "J-103",
        "customer_name": null,
        "address": "8 LB Road, Adyar, Chennai",
        "scheduled_at": "2026-11-25 13:15",
        "status": "pending",
        "notes": ""
      },
      {
        "id": "J-104",
        "customer_name": "Karthik Rajan",
        "address": "23 OMR, Sholinganallur, Chennai",
        "scheduled_at": "2026-11-25 15:45",
        "status": "completed",
        "notes": "Gutter replacement done. Collect payment."
      },
      {
        "id": "J-105",
        "customer_name": "Meena Lakshmi",
        "address": "",
        "scheduled_at": "2026-11-25 17:30",
        "status": "pending",
        "notes": "Solar panel inspection. Address to be confirmed by office."
      }
    ]
    """

    static func jobObject(
        id: String = "T-1",
        scheduledAt: String = "2026-11-25 10:00",
        status: String = "pending"
    ) -> String {
        """
        {"id": "\(id)", "customer_name": "Test", "address": "1 Test St", \
        "scheduled_at": "\(scheduledAt)", "status": "\(status)"}
        """
    }

    static func jobsArray(_ objects: [String]) -> String {
        "[" + objects.joined(separator: ",") + "]"
    }

    static func job(scheduledAt: String = "2026-11-25 10:00", status: String = "pending") -> String {
        jobsArray([jobObject(scheduledAt: scheduledAt, status: status)])
    }
}

import Foundation
import UIKit

enum HistoryExportFormat {
    case csv
    case pdf
}

/// Produces a dose-history summary for sharing with a clinician (spec section 13:
/// "L'export local d'un résumé PDF ou CSV" + "Le partage via la feuille de partage
/// iOS"). Distinct from `DataExportServicing`, which exports the full raw dataset for
/// the user's own records.
@MainActor
protocol HistoryExportServicing {
    func export(events: [DoseEvent], profileName: String, format: HistoryExportFormat) throws -> URL
}

@MainActor
final class HistoryExportService: HistoryExportServicing {
    func export(events: [DoseEvent], profileName: String, format: HistoryExportFormat) throws -> URL {
        switch format {
        case .csv:
            return try exportCSV(events: events, profileName: profileName)
        case .pdf:
            return try exportPDF(events: events, profileName: profileName)
        }
    }

    private func exportCSV(events: [DoseEvent], profileName: String) throws -> URL {
        var lines = ["Date,Scheduled Time,Status,Taken At,Delay (min),Note"]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        for event in events.sorted(by: { $0.scheduledDate < $1.scheduledDate }) {
            let date = dateFormatter.string(from: event.scheduledDate)
            let time = timeFormatter.string(from: event.scheduledTime)
            let status = event.status.rawValue
            let takenAt = event.actualTakenDate.map(timeFormatter.string(from:)) ?? ""
            let note = (event.userNote ?? "").replacingOccurrences(of: ",", with: ";")
            lines.append("\(date),\(time),\(status),\(takenAt),\(event.delayMinutes),\(note)")
        }

        let csv = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pillo-history-\(Int(Date.now.timeIntervalSince1970)).csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func exportPDF(events: [DoseEvent], profileName: String) throws -> URL {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 36
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 18)]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.gray]
        let rowAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11)]

        let data = renderer.pdfData { context in
            var y: CGFloat = margin
            var startedPage = false

            func newPageIfNeeded(_ neededHeight: CGFloat) {
                if !startedPage || y + neededHeight > pageHeight - margin {
                    context.beginPage()
                    startedPage = true
                    y = margin
                }
            }

            newPageIfNeeded(60)
            NSString(string: "Pillo — \(profileName)").draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttributes)
            y += 26
            NSString(string: "Exported \(dateFormatter.string(from: .now))").draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttributes)
            y += 30

            for event in events.sorted(by: { $0.scheduledDate < $1.scheduledDate }) {
                newPageIfNeeded(18)
                let takenText = event.actualTakenDate.map { "taken \(timeFormatter.string(from: $0))" } ?? "—"
                let line = "\(dateFormatter.string(from: event.scheduledDate))  •  \(timeFormatter.string(from: event.scheduledTime))  •  \(event.status.rawValue)  •  \(takenText)"
                NSString(string: line).draw(at: CGPoint(x: margin, y: y), withAttributes: rowAttributes)
                y += 16
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pillo-history-\(Int(Date.now.timeIntervalSince1970)).pdf")
        try data.write(to: url, options: .atomic)
        return url
    }
}

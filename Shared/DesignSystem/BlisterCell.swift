import SwiftUI

/// Visual state for one blister-grid cell. Always derived on the fly from `DoseEvent` +
/// the calendar day being rendered — never stored separately, so Home/Plaquette/Suivi
/// can never disagree about what a given day looked like.
enum BlisterCellState: String {
    case taken
    case takenLate
    case missed
    case placeboTaken
    case today
    case placeboUpcoming
    case upcoming
    /// No `DoseEvent` at all for this day — a pause/stop day.
    case pause

    static func make(event: DoseEvent?, isToday: Bool) -> BlisterCellState {
        guard let event else { return .pause }
        switch event.status {
        case .takenOnTime:
            return .taken
        case .takenLate:
            return .takenLate
        case .missed:
            return .missed
        case .placebo:
            return event.actualTakenDate != nil ? .placeboTaken : (isToday ? .today : .placeboUpcoming)
        case .scheduled, .unknown, .skipped:
            return isToday ? .today : .upcoming
        }
    }

    /// Used by the widget/watch targets, which only have the already-computed cell state
    /// (via `WidgetSnapshot.BlisterCell.statusRaw`, written by `WidgetBridge` on the phone)
    /// rather than a live `DoseEvent` — no scheduling logic duplicated on that side.
    static func make(rawStatus: String) -> BlisterCellState {
        BlisterCellState(rawValue: rawStatus) ?? .pause
    }

    var fillColor: Color {
        switch self {
        case .taken, .placeboTaken: return Palette.success
        case .takenLate: return Palette.warning
        case .missed: return Palette.danger
        case .today: return Palette.primary
        case .placeboUpcoming: return Palette.primary.opacity(0.25)
        case .upcoming: return Palette.primary.opacity(0.12)
        case .pause: return Palette.textSecondary.opacity(0.10)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .taken, .takenLate, .missed, .today, .placeboTaken: return .white
        default: return Palette.textSecondary
        }
    }

    var systemImage: String? {
        switch self {
        case .taken, .placeboTaken: return "checkmark"
        case .takenLate: return "checkmark"
        case .missed: return "xmark"
        default: return nil
        }
    }

    var accessibilityDescription: LocalizedStringKey {
        switch self {
        case .taken, .takenLate: return "blister.cell.taken"
        case .placeboTaken: return "blister.cell.placeboTaken"
        case .missed: return "blister.cell.missed"
        case .today: return "blister.cell.today"
        case .placeboUpcoming: return "blister.cell.placeboUpcoming"
        case .upcoming: return "blister.cell.upcoming"
        case .pause: return "blister.cell.pause"
        }
    }
}

struct BlisterCellView: View {
    let dayNumber: Int
    let state: BlisterCellState
    var showsNumber = true

    var body: some View {
        ZStack {
            Circle().fill(state.fillColor)
            if let systemImage = state.systemImage {
                Image(systemName: systemImage).font(.caption.bold())
            } else if showsNumber && state != .pause {
                Text("\(dayNumber)").font(.caption2.monospacedDigit())
            }
            if state == .today {
                Circle().stroke(Palette.primaryDeep, lineWidth: 2)
            }
        }
        .foregroundStyle(state.foregroundColor)
        .accessibilityLabel(Text("\(dayNumber): ") + Text(state.accessibilityDescription))
    }
}

extension BlisterCellState: Equatable {}

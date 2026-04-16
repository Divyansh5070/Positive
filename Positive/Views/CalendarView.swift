
import SwiftUI

// MARK: - Shared formatters (never allocate more than once)
private let monthYearFmt: DateFormatter = {
    let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f
}()
private let dayKeyFmt: DateFormatter = {
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
}()
private let shortMonthFmt: DateFormatter = {
    let f = DateFormatter(); f.dateFormat = "MMM"; return f
}()

// MARK: - CalendarView
struct CalendarView: View {
    @EnvironmentObject var store: DataStore
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date? = Calendar.current.startOfDay(for: Date())

    private let calendar = Calendar.current
    private let dayLabels: [(Int, String)] = [
        (0,"S"),(1,"M"),(2,"T"),(3,"W"),(4,"T"),(5,"F"),(6,"S")
    ]

    var youDates: Set<String>   { store.datesWithEntries(for: .you,   in: displayedMonth) }
    var buddyDates: Set<String> { store.datesWithEntries(for: .buddy, in: displayedMonth) }
    var selectedDateEntries: [LCEntry] {
        guard let selectedDate else { return [] }
        return store.entries
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            DottedBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Header
                    HStack {
                        Text("Calendar")
                            .font(.caveatBold(34))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("📅").font(.system(size: 28))
                    }

                    // ── Monthly calendar card ─────────────────────────────
                    VStack(spacing: 16) {
                        // Month navigation
                        HStack {
                            Button {
                                withAnimation {
                                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.textPrimary)
                            }

                            Spacer()
                            Text(monthYearFmt.string(from: displayedMonth))
                                .font(.caveat(22, weight: .bold))
                                .foregroundColor(.textPrimary)
                            Spacer()

                            Button {
                                withAnimation {
                                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.textPrimary)
                            }
                        }

                        // Day labels
                        HStack(spacing: 0) {
                            ForEach(dayLabels, id: \.0) { (_, label) in
                                Text(label)
                                    .font(.caveat(15, weight: .bold))
                                    .foregroundColor(.textPrimary.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        // Days grid
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                            spacing: 6
                        ) {
                            ForEach(Array(gridDays.enumerated()), id: \.offset) { (_, day) in
                                if let day = day {
                                    CalendarDayCell(
                                        day: day,
                                        isYou:   youDates.contains(dayKeyFmt.string(from: day)),
                                        isBuddy: buddyDates.contains(dayKeyFmt.string(from: day)),
                                        isToday: calendar.isDateInToday(day),
                                        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedDate = day
                                        }
                                    }
                                } else {
                                    Color.clear.frame(height: 36)
                                }
                            }
                        }

                        // Legend
                        HStack(spacing: 20) {
                            LegendItem(color: .userBlue,    label: store.myProfile?.displayName ?? "You")
                            if store.isConnected {
                                LegendItem(color: .mediumYellow, label: store.buddyProfile?.displayName ?? "Buddy")
                                LegendItem(color: .bothGreen,    label: "Both")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .sketchCard()

                    // ── Selected date activity ────────────────────────────
                    if let selectedDate {
                        SelectedDateActivityCard(
                            date: selectedDate,
                            entries: selectedDateEntries,
                            myName: store.myProfile?.displayName ?? "You",
                            buddyName: store.buddyProfile?.displayName ?? "Buddy"
                        )
                    }

                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 20)
                .padding(.top, 1)
            }
        }
    }

    // MARK: Helpers
    var gridDays: [Date?] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
            let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        let totalDays = calendar.dateComponents([.day],
            from: monthInterval.start,
            to: monthInterval.end
        ).day!

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for d in 0..<totalDays {
            days.append(calendar.date(byAdding: .day, value: d, to: firstDay))
        }
        return days
    }
}

// MARK: - Heat Map Card
struct HeatMapCard: View {
    @EnvironmentObject var store: DataStore
    @State private var tappedDay: HeatDay? = nil

    private let calendar  = Calendar.current
    private let weeks     = 16
    private let cellSize: CGFloat = 13
    private let cellSpacing: CGFloat = 4

    // Build a 2-D grid: [weekCol][dayRow] where weekCol 0 = oldest
    var heatGrid: [[HeatDay]] {
        // Anchor to today, go back `weeks` full weeks
        let today    = calendar.startOfDay(for: Date())
        // Weekday index 0=Sun…6=Sat
        let todayWday = calendar.component(.weekday, from: today) - 1
        // Start of the grid = start of the oldest week
        let gridStart = calendar.date(byAdding: .day, value: -(weeks * 7 - 1 + todayWday), to: today)!

        // Count entries per day key for fast lookup
        var counts: [String: Int] = [:]
        for entry in store.myEntries {
            let k = dayKeyFmt.string(from: entry.date)
            counts[k, default: 0] += 1
        }

        var grid: [[HeatDay]] = []
        for week in 0..<weeks {
            var col: [HeatDay] = []
            for dow in 0..<7 {
                let offset = week * 7 + dow
                let date   = calendar.date(byAdding: .day, value: offset, to: gridStart)!
                if date > today { break }   // don't include future cells
                let key    = dayKeyFmt.string(from: date)
                col.append(HeatDay(date: date, count: counts[key] ?? 0))
            }
            grid.append(col)
        }
        return grid
    }

    // Month labels: one per column where month changes
    var monthLabels: [(col: Int, label: String)] {
        var result: [(Int, String)] = []
        var lastMonth = -1
        for (i, col) in heatGrid.enumerated() {
            if let first = col.first {
                let m = calendar.component(.month, from: first.date)
                if m != lastMonth {
                    result.append((i, shortMonthFmt.string(from: first.date)))
                    lastMonth = m
                }
            }
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {

                    // Month labels
                    ZStack(alignment: .topLeading) {
                        Color.clear.frame(height: 16)
                        ForEach(monthLabels, id: \.col) { item in
                            Text(item.label)
                                .font(.caveat(12))
                                .foregroundColor(.textPrimary.opacity(0.45))
                                .offset(x: CGFloat(item.col) * (cellSize + cellSpacing))
                        }
                    }

                    // Grid panel
                    HStack(alignment: .top, spacing: cellSpacing) {
                        // Day-of-week axis (M/W/F labels)
                        VStack(spacing: cellSpacing) {
                            ForEach(Array(["", "M", "", "W", "", "F", ""].enumerated()), id: \.offset) { _, lbl in
                                Text(lbl)
                                    .font(.caveat(10))
                                    .foregroundColor(.textPrimary.opacity(0.38))
                                    .frame(width: 11, height: cellSize)
                            }
                        }

                        HStack(alignment: .top, spacing: cellSpacing) {
                            ForEach(Array(heatGrid.enumerated()), id: \.offset) { _, col in
                                VStack(spacing: cellSpacing) {
                                    ForEach(col) { day in
                                        heatCell(day)
                                    }
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.cardBackground.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.sketchBorder.opacity(0.35), lineWidth: 1.2)
                    )
                }
                .padding(.vertical, 4)
            }

            HStack(spacing: 7) {
                Text("Less")
                    .font(.caveat(12))
                    .foregroundColor(.textPrimary.opacity(0.4))
                ForEach(0..<5) { lvl in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(heatColor(for: lvl == 0 ? 0 : lvl == 1 ? 1 : lvl == 2 ? 2 : lvl == 3 ? 4 : 7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.sketchBorder.opacity(0.3), lineWidth: 0.7)
                        )
                        .frame(width: 13, height: 13)
                }
                Text("More")
                    .font(.caveat(12))
                    .foregroundColor(.textPrimary.opacity(0.4))
            }
        }
        .sketchCard()
    }

    @ViewBuilder
    private func heatCell(_ day: HeatDay) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(heatColor(for: day.count))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        tappedDay?.id == day.id ? Color.textPrimary : Color.sketchBorder.opacity(0.2),
                        lineWidth: tappedDay?.id == day.id ? 1.3 : 0.6
                    )
            )
            .frame(width: cellSize, height: cellSize)
            .scaleEffect(tappedDay?.id == day.id ? 1.18 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.6), value: tappedDay?.id)
            .onTapGesture {
                withAnimation {
                    tappedDay = (tappedDay?.id == day.id) ? nil : day
                }
            }
    }

    // 5-level heat colour using existing palette
    func heatColor(for count: Int) -> Color {
        switch count {
        case 0:        return Color.cardBackground
        case 1:        return Color.userBlue.opacity(0.35)
        case 2...3:    return Color.userBlue.opacity(0.58)
        case 4...5:    return Color.mediumYellow.opacity(0.75)
        default:       return Color.bothGreen.opacity(0.95)
        }
    }
}

// MARK: - Heat Day model
struct HeatDay: Identifiable {
    let id    = UUID()
    let date: Date
    let count: Int
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let day: Date
    let isYou: Bool
    let isBuddy: Bool
    let isToday: Bool
    let isSelected: Bool

    private let calendar = Calendar.current

    var bgColor: Color {
        if isYou && isBuddy { return .bothGreen }
        if isYou            { return .userBlue }
        if isBuddy          { return .mediumYellow }
        return Color.cardBackground
    }

    var dayNum: Int { calendar.component(.day, from: day) }
    var hasActivity: Bool { isYou || isBuddy }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text("\(dayNum)")
                .font(.caveat(15, weight: hasActivity ? .bold : .regular))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(bgColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.textPrimary : (isToday ? Color.sketchBorder : Color.sketchBorder.opacity(0.25)),
                            lineWidth: isSelected ? 2.5 : (isToday ? 2 : 1)
                        )
                )

            if hasActivity {
                Text("⭐")
                    .font(.system(size: 8))
                    .offset(x: 2, y: -2)
            }
        }
    }
}

// MARK: - Selected Date Activity
private struct SelectedDateActivityCard: View {
    let date: Date
    let entries: [LCEntry]
    let myName: String
    let buddyName: String

    private static let headerFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity on \(Self.headerFmt.string(from: date))")
                    .font(.caveat(22, weight: .bold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(entries.count) problem\(entries.count == 1 ? "" : "s")")
                    .font(.caveat(14))
                    .foregroundColor(.textPrimary.opacity(0.55))
            }

            if entries.isEmpty {
                Text("No problems attempted or added on this date.")
                    .font(.caveat(16))
                    .foregroundColor(.textPrimary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                ForEach(entries) { entry in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(entry.user == .you ? Color.userBlue : Color.buddyPink)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(String((entry.user == .you ? myName : buddyName).prefix(1)).uppercased())
                                    .font(.caveatBold(14))
                                    .foregroundColor(.white)
                            )
                            .overlay(Circle().stroke(Color.sketchBorder, lineWidth: 1))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(entry.lcNumber). \(entry.problemName)")
                                .font(.caveat(17, weight: .bold))
                                .foregroundColor(.textPrimary)
                                .lineLimit(2)
                            Text("\(entry.user == .you ? myName : buddyName) • \(Self.timeFmt.string(from: entry.date))")
                                .font(.caveat(13))
                                .foregroundColor(.textPrimary.opacity(0.5))
                        }

                        Spacer()
                        DifficultyBadge(difficulty: entry.difficulty)
                    }
                    .padding(10)
                    .background(Color.tagBackground.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.sketchBorder.opacity(0.25), lineWidth: 1)
                    )
                }
            }
        }
        .sketchCard()
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 16, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.sketchBorder, lineWidth: 1)
                )
            Text(label)
                .font(.caveat(15))
                .foregroundColor(.textPrimary)
        }
    }
}

#Preview {
    CalendarView().environmentObject(DataStore.shared)
}

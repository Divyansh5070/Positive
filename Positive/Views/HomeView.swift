
import SwiftUI

// MARK: - HomeView
struct HomeView: View {
    @EnvironmentObject var store: DataStore
    @StateObject private var auth = AuthViewModel.shared
    @Binding var showAddQuestion: Bool
    @State private var showBuddy      = false
    @State private var showTasksSheet = false
    @State private var selectedEntry: LCEntry? = nil
    @State private var pulseBadge     = false
    @State private var showQuoteCard  = true

    var myName: String    { store.myProfile?.displayName ?? "You" }
    var buddyName: String { store.buddyProfile?.displayName ?? "Buddy" }

    // Rotating motivational quotes
    private let quotes: [(text: String, emoji: String)] = [
        ("Consistency beats talent every single day.", "⚡"),
        ("One problem a day keeps unemployment away.", "💼"),
        ("Show up. Grind. Repeat.", "🔁"),
        ("Hard problems build strong engineers.", "🏋️"),
        ("Small wins compound into big results.", "📈"),
        ("The algorithm doesn't care about your mood.", "🤖"),
    ]
    private var dailyQuote: (text: String, emoji: String) {
        let idx = Calendar.current.component(.day, from: Date()) % quotes.count
        return quotes[idx]
    }

    var body: some View {
        ZStack {
            DottedBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Header ──────────────────────────────────────────
                    headerSection

             
                    // ── Weekly progress ring ──────────────────────────
                    WeeklyRingCard()

//                    // ── Quote of the day ─────────────────────────────
//                    if showQuoteCard {
//                        QuoteCard(quote: dailyQuote, onDismiss: {
//                            withAnimation(.easeOut(duration: 0.2)) { showQuoteCard = false }
//                        })
//                    }
                    
                    // ── Add question CTA ──────────────────────────────
                    TodayTasksCard {
                        showTasksSheet = true
                    }

                    // ── Add question CTA ──────────────────────────────
                    Button { showAddQuestion = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                            Text("Add Today's Problem")
                                .font(.caveat(22, weight: .bold))
                        }
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(SketchButtonStyle(fillColor: .accentYellow))
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        TapGesture().onEnded { showAddQuestion = true }
                    )


                    // ── Today's progress ─────────────────────────────
//                    todayProgressCard

                  
                    // ── Contribution graph ─────────────────────────────
                    HeatMapCard()
                    
                    // ── Difficulty breakdown ───────────────────────────
                    DifficultyBreakdownCard()

                    // ── Buddy banner ──────────────────────────────────
                    buddyBanner

                  
                    // ── Recent Activity ───────────────────────────────
                    if !store.entries.isEmpty {
                        recentActivity
                    }

                    Spacer(minLength: 130)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }

            // Entry Detail Overlay
            if let entry = selectedEntry {
                EntryDetailOverlay(
                    entry: entry,
                    myName: myName,
                    buddyName: buddyName,
                    onDismiss: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedEntry = nil
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(10)
            }
        }
        .sheet(isPresented: $showBuddy) {
            BuddyView().environmentObject(store)
        }
        .sheet(isPresented: $showTasksSheet) {
            TodoTasksSheet(isPresented: $showTasksSheet)
                .environmentObject(store)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(Color.userBlue)
                    .frame(width: 46, height: 46)
                    .overlay(Circle().stroke(Color.sketchBorder, lineWidth: 2))
                Text(String(myName.prefix(1)).uppercased())
                    .font(.caveatBold(22))
                    .foregroundColor(.white)
            }

            // Greeting + name
            VStack(alignment: .leading, spacing: 1) {
                Text(greetingText)
                    .font(.caveat(14))
                    .foregroundColor(.textPrimary.opacity(0.45))
                Text(myName)
                    .font(.caveatBold(22))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            // Streak badge + sign-out
            HStack(spacing: 8) {
                streakBadge
                Button { auth.signOut() } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textPrimary.opacity(0.55))
                        .frame(width: 38, height: 38)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                        .overlay(RoundedRectangle(cornerRadius: 11)
                            .stroke(Color.sketchBorder, lineWidth: 1.5))
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var streakBadge: some View {
        HStack(spacing: 5) {
            Text("🔥")
                .font(.system(size: 15))
                .scaleEffect(pulseBadge ? 1.3 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.4).repeatCount(2), value: pulseBadge)
            Text("\(store.streak)d")
                .font(.caveatBold(17))
                .foregroundColor(.textPrimary)
            Text("streak")
                .font(.caveat(14))
                .foregroundColor(.textPrimary.opacity(0.55))
        }
        .fixedSize()                          // never wrap — always single line
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(store.streak > 0 ? Color.accentYellow.opacity(0.3) : Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(store.streak > 0 ? Color.accentYellow : Color.sketchBorder, lineWidth: 2))
        .onAppear { if store.streak > 0 { pulseBadge = true } }
    }

    private var greetingText: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12:  return "Good morning 🌤"
        case 12..<17: return "Good afternoon ☀️"
        case 17..<21: return "Good evening 🌆"
        default:      return "Late night grind 🌙"
        }
    }

    // MARK: - Today Progress Card
    private var todayProgressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Progress")
                        .font(.caveat(22, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text(todayDateString)
                        .font(.caveat(13))
                        .foregroundColor(.textPrimary.opacity(0.4))
                }
                Spacer()
                // Today total badge
                Text("\(store.youTodayCount + (store.isConnected ? store.buddyTodayCount : 0)) solved")
                    .font(.caveat(14, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.easyGreen.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.sketchBorder.opacity(0.4), lineWidth: 1))
            }

            Rectangle()
                .fill(Color.sketchBorder.opacity(0.2))
                .frame(height: 1)

            if store.isConnected {
                HStack(spacing: 0) {
                    progressColumn(name: myName,    count: store.youTodayCount,   color: .userBlue)
                    Rectangle()
                        .fill(Color.sketchBorder.opacity(0.25))
                        .frame(width: 1, height: 70)
                    progressColumn(name: buddyName, count: store.buddyTodayCount, color: .buddyPink)
                }
            } else {
                progressColumn(name: myName, count: store.youTodayCount, color: .userBlue)
                    .frame(maxWidth: .infinity)
            }

            // Motivation banner
            if store.isConnected && store.youTodayCount > 0 && store.buddyTodayCount > 0 {
                motivationBadge("You both crushed it today! 🎉")
            } else if store.youTodayCount == 0 {
                motivationBadge("No solves yet — start the streak! 💪")
            } else {
                motivationBadge("Great work — keep pushing! 🚀")
            }
        }
        .sketchCard()
    }

    // MARK: - Recent Activity
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("⭐")
                Text("Recent Activity")
                    .font(.caveat(22, weight: .bold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("Last \(min(store.entries.count, 5))")
                    .font(.caveat(13))
                    .foregroundColor(.textPrimary.opacity(0.4))
            }
            ForEach(store.entries.prefix(5)) { entry in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedEntry = entry
                    }
                } label: {
                    RecentActivityRow(entry: entry, myName: myName, buddyName: buddyName)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Buddy Banner
    @ViewBuilder
    private var buddyBanner: some View {
        if store.isConnected {
            HStack(spacing: 10) {
                Circle().fill(Color.bothGreen).frame(width: 8, height: 8)
                Text("Connected with \(buddyName)")
                    .font(.caveat(15, weight: .bold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Button { showBuddy = true } label: {
                    Text("Manage")
                        .font(.caveat(13))
                        .foregroundColor(.userBlue)
                        .underline()
                }
            }
            .padding(12)
            .background(Color.bothGreen.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bothGreen, lineWidth: 1.5))
        } else {
            Button { showBuddy = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill").foregroundColor(.userBlue)
                    Text("Connect with a Buddy")
                        .font(.caveat(17, weight: .bold)).foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12)).foregroundColor(.textPrimary.opacity(0.4))
                }
                .padding(14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sketchBorder, lineWidth: 1.5))
            }
        }
    }

    // MARK: - Helpers
    private func progressColumn(name: String, count: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(color)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.sketchBorder, lineWidth: 1.5))
                Text(String(name.prefix(1)).uppercased())
                    .font(.caveatBold(22)).foregroundColor(.white)
            }
            Text("\(count)")
                .font(.caveatBold(28))
                .foregroundColor(.textPrimary)
            Text("\(count == 1 ? "problem" : "problems") solved")
                .font(.caveat(13))
                .foregroundColor(.textPrimary.opacity(0.5))
            Text(name)
                .font(.caveat(12))
                .foregroundColor(.textPrimary.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }

    private func motivationBadge(_ text: String) -> some View {
        Text(text)
            .font(.caveat(16, weight: .bold))
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.accentYellow.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(Color.sketchBorder.opacity(0.4), lineWidth: 1.5))
    }

    private var todayDateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMM"
        return f.string(from: Date())
    }
}

// MARK: - Quote of the Day Card
struct QuoteCard: View {
    let quote: (text: String, emoji: String)
    let onDismiss: () -> Void
    @State private var appear = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(quote.emoji)
                .font(.system(size: 30))

            VStack(alignment: .leading, spacing: 4) {
                Text("Quote of the Day")
                    .font(.caveat(12))
                    .foregroundColor(.textPrimary.opacity(0.4))
                    .kerning(1)
                Text(quote.text)
                    .font(.caveat(17, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textPrimary.opacity(0.35))
                    .padding(6)
                    .background(Color.tagBackground)
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.sketchBorder.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: Color.sketchBorder.opacity(0.08), radius: 0, x: 2, y: 3)
        .scaleEffect(appear ? 1.0 : 0.95)
        .opacity(appear ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { appear = true }
        }
    }
}

// MARK: - Weekly Progress Ring Card
struct WeeklyRingCard: View {
    @EnvironmentObject var store: DataStore
    @State private var animate = false

    var progress: Double {
        guard store.weeklyGoal > 0 else { return 0 }
        return min(Double(store.weeklyProgress) / Double(store.weeklyGoal), 1.0)
    }

    var body: some View {
        HStack(spacing: 20) {
            // Ring
            ZStack {
                Circle()
                    .stroke(Color.tagBackground, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: animate ? progress : 0)
                    .stroke(
                        progress >= 1.0 ? Color.bothGreen : Color.accentYellow,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.65), value: animate)

                VStack(spacing: 0) {
                    Text("\(store.weeklyProgress)")
                        .font(.caveatBold(26))
                        .foregroundColor(.textPrimary)
                    Text("/ \(store.weeklyGoal)")
                        .font(.caveat(13))
                        .foregroundColor(.textPrimary.opacity(0.4))
                }
            }
            .frame(width: 84, height: 84)
            .overlay(
                Circle()
                    .stroke(Color.sketchBorder.opacity(0.12), lineWidth: 1)
            )
            .onAppear { animate = true }

            // Text
            VStack(alignment: .leading, spacing: 6) {
                Text("Weekly Goal")
                    .font(.caveat(22, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text(progress >= 1.0
                     ? "🎉 Goal smashed! "
                     : "\(store.weeklyGoal - store.weeklyProgress) more to hit your goal")
                    .font(.caveat(15))
                    .foregroundColor(.textPrimary.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)

                // Mini progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.tagBackground)
                            .frame(height: 7)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progress >= 1.0 ? Color.bothGreen : Color.accentYellow)
                            .frame(width: geo.size.width * (animate ? progress : 0), height: 7)
                            .animation(.spring(response: 0.8, dampingFraction: 0.65), value: animate)
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.sketchBorder.opacity(0.2), lineWidth: 0.8)
                            .frame(height: 7)
                    }
                }
                .frame(height: 7)
            }
        }
        .sketchCard()
    }
}

// MARK: - Difficulty Breakdown Card
struct DifficultyBreakdownCard: View {
    @EnvironmentObject var store: DataStore
    @State private var animate = false

    var totalYou: Int { store.myEntries.count }
    var easy:   Int { store.entriesBy(user: .you, difficulty: .easy) }
    var medium: Int { store.entriesBy(user: .you, difficulty: .medium) }
    var hard:   Int { store.entriesBy(user: .you, difficulty: .hard) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your Breakdown")
                    .font(.caveat(22, weight: .bold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(totalYou) total")
                    .font(.caveat(14))
                    .foregroundColor(.textPrimary.opacity(0.4))
            }

            VStack(spacing: 10) {
                diffRow(label: "Easy",   count: easy,   total: totalYou, color: .easyGreen)
                diffRow(label: "Medium", count: medium, total: totalYou, color: .mediumYellow)
                diffRow(label: "Hard",   count: hard,   total: totalYou, color: .hardRed)
            }
        }
        .sketchCard()
        .onAppear { withAnimation(.easeOut(duration: 0.1)) { animate = true } }
    }

    private func diffRow(label: String, count: Int, total: Int, color: Color) -> some View {
        let ratio = total > 0 ? Double(count) / Double(total) : 0
        return HStack(spacing: 10) {
            Text(label)
                .font(.caveat(15, weight: .bold))
                .foregroundColor(.textPrimary)
                .frame(width: 54, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.tagBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.sketchBorder.opacity(0.2), lineWidth: 0.8)
                        )
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color)
                        .frame(width: geo.size.width * (animate ? ratio : 0))
                        .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.05), value: animate)
                }
                .frame(height: 14)
            }
            .frame(height: 14)

            Text("\(count)")
                .font(.caveatBold(16))
                .foregroundColor(.textPrimary)
                .frame(width: 28, alignment: .trailing)
        }
    }
}

// MARK: - Recent Activity Row
struct RecentActivityRow: View {
    let entry: LCEntry
    let myName: String
    let buddyName: String

    var displayName: String { entry.user == .you ? myName : buddyName }
    var dotColor: Color { entry.user == .you ? .userBlue : .buddyPink }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(dotColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(displayName.prefix(1)).uppercased())
                        .font(.caveatBold(16))
                        .foregroundColor(.white)
                )
                .overlay(Circle().stroke(Color.sketchBorder, lineWidth: 1.5))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.lcNumber). \(entry.problemName)")
                    .font(.caveat(17, weight: .bold))
                    .foregroundColor(.textPrimary)
                HStack(spacing: 6) {
                    ForEach(entry.categories, id: \.self) { cat in
                        CategoryTag(category: cat)
                    }
                }
            }
            Spacer()
            DifficultyBadge(difficulty: entry.difficulty)
        }
        .sketchCard(padding: 14)
    }
}

struct TodayTasksCard: View {
    @EnvironmentObject var store: DataStore
    let onTap: () -> Void

    private var progressBoxes: [Bool] {
        let total = max(store.todayMyTodos.count, 3)
        let done = store.todayMyTodos.filter(\.isCompleted).count
        return (0..<min(total, 4)).map { $0 < done }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 23, weight: .semibold))
                        Text("Today's Tasks")
                            .font(.caveatBold(20))
                    }
                    .foregroundColor(.textPrimary)

                    Spacer()

                    Text("\(store.remainingTodayTodoCount) remaining")
                        .font(.caveat(13, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.cardBackground.opacity(0.6))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.sketchBorder.opacity(0.25), lineWidth: 1))
                }

                HStack(spacing: 7) {
                    ForEach(Array(progressBoxes.enumerated()), id: \.offset) { _, filled in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(filled ? Color.textPrimary : Color.cardBackground)
                            .frame(width: 16, height: 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.sketchBorder, lineWidth: 1.6)
                            )
                    }
                    Spacer()
                    Text("tap to open")
                        .font(.caveat(18))
                        .foregroundColor(.textPrimary.opacity(0.7))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textPrimary.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color.accentYellow.opacity(0.85))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.sketchBorder, lineWidth: 2)
            )
            .shadow(color: Color.sketchBorder.opacity(0.2), radius: 0, x: 3, y: 5)
        }
        .buttonStyle(.plain)
    }
}

struct TodoTasksSheet: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool

    @State private var newTask = ""
    @State private var newTaskTag: TodoTag? = nil

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    var body: some View {
        ZStack {
            DottedBackground()

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Tasks 📋")
                            .font(.caveatBold(19))
                            .foregroundColor(.textPrimary)
                        Text(dateFormatter.string(from: Date()))
                            .font(.caveat(14))
                            .foregroundColor(.textPrimary.opacity(0.5))
                    }
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .padding(6)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 12)

                Rectangle()
                    .fill(Color.sketchBorder.opacity(0.45))
                    .frame(height: 1)
                    .overlay(
                        Rectangle()
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 2]))
                            .foregroundColor(Color.sketchBorder.opacity(0.35))
                    )
                    .padding(.horizontal, 16)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        sectionBadge("Your Tasks", color: .userBlue.opacity(0.85))

                        if store.todayMyTodos.isEmpty {
                            Text("No tasks yet. Add one below.")
                                .font(.caveat(16))
                                .foregroundColor(.textPrimary.opacity(0.5))
                        } else {
                            ForEach(store.todayMyTodos) { task in
                                TodoRow(
                                    task: task,
                                    canEdit: true,
                                    onToggle: { toggled in
                                        store.toggleTodoCompletion(id: task.id, isCompleted: toggled)
                                    },
                                    onDelete: {
                                        store.deleteTodo(id: task.id)
                                    }
                                )
                            }
                        }

                        addTaskRow

                        if store.isConnected {
                            sectionBadge("Buddy's Tasks", color: .buddyPink.opacity(0.85))
                            if store.todayBuddyTodos.isEmpty {
                                Text("No buddy tasks for today.")
                                    .font(.caveat(16))
                                    .foregroundColor(.textPrimary.opacity(0.5))
                            } else {
                                ForEach(store.todayBuddyTodos) { task in
                                    TodoRow(
                                        task: task,
                                        canEdit: false,
                                        onToggle: { _ in },
                                        onDelete: {}
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.sketchBorder, lineWidth: 2)
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private var addTaskRow: some View {
        HStack(spacing: 8) {
            TextField("Add a task...", text: $newTask)
                .font(.caveat(20))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.clear)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.sketchBorder.opacity(0.35))
                        .frame(height: 1)
                }

            Menu {
                Button("Other") { newTaskTag = .other }
                ForEach(TodoTag.allCases, id: \.self) { tag in
                    Button(tag.rawValue) { newTaskTag = tag }
                }
            } label: {
                Text(taskLabelText)
                    .font(.caveat(14, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(taskLabelColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.sketchBorder.opacity(0.6), lineWidth: 1)
                    )
            }

            Button {
                let title = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty else { return }
                store.addTodo(
                    TodoItem(
                        title: title,
                        isCompleted: false,
                        tag: newTaskTag,
                        user: .you,
                        date: Date(),
                        ownerUID: ""
                    )
                )
                newTask = ""
                newTaskTag = nil
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(Color.userBlue.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.sketchBorder, lineWidth: 1.5)
                    )
            }
        }
    }

    private var taskLabelText: String {
        newTaskTag?.rawValue ?? "Other"
    }

    private var taskLabelColor: Color {
        guard let tag = newTaskTag else { return Color.tagBackground }
        switch tag {
        case .leetcode: return Color.mediumYellow.opacity(0.7)
        case .academic: return Color.userBlue.opacity(0.6)
        case .development: return Color.buddyPink.opacity(0.6)
        case .other: return Color.tagBackground
        }
    }

    private func sectionBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caveat(22, weight: .bold))
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.sketchBorder.opacity(0.6), lineWidth: 1)
            )
    }
}

private struct TodoRow: View {
    let task: TodoItem
    let canEdit: Bool
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                if canEdit {
                    onToggle(!task.isCompleted)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundColor(task.isCompleted ? .textPrimary.opacity(0.55) : .textPrimary)
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.caveat(18, weight: .bold))
                .foregroundColor(.textPrimary.opacity(task.isCompleted ? 0.6 : 1))
                .strikethrough(task.isCompleted, color: Color.textPrimary.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(task.tag?.rawValue ?? "Other")
                .font(.caveat(13, weight: .bold))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(labelColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.sketchBorder.opacity(0.5), lineWidth: 1)
                )

            if canEdit {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textPrimary.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var labelColor: Color {
        guard let tag = task.tag else { return Color.tagBackground }
        switch tag {
        case .leetcode: return Color.mediumYellow.opacity(0.55)
        case .academic: return Color.userBlue.opacity(0.55)
        case .development: return Color.buddyPink.opacity(0.55)
        case .other: return Color.tagBackground
        }
    }
}

#Preview {
    HomeView(showAddQuestion: .constant(false))
        .environmentObject(DataStore.shared)
}

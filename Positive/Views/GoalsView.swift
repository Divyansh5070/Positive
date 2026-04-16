
import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var store: DataStore

    var myName: String    { store.myProfile?.displayName ?? "You" }
    var buddyName: String { store.buddyProfile?.displayName ?? "Buddy" }

    var youEasy: Int    { store.entriesBy(user: .you,   difficulty: .easy) }
    var youMedium: Int  { store.entriesBy(user: .you,   difficulty: .medium) }
    var youHard: Int    { store.entriesBy(user: .you,   difficulty: .hard) }
    var buddyEasy: Int  { store.entriesBy(user: .buddy, difficulty: .easy) }
    var buddyMedium: Int { store.entriesBy(user: .buddy, difficulty: .medium) }
    var buddyHard: Int  { store.entriesBy(user: .buddy, difficulty: .hard) }

    var progressFraction: Double {
        min(Double(store.weeklyProgress) / Double(max(store.weeklyGoal, 1)), 1.0)
    }

    var motivationText: String {
        let f = progressFraction
        if f >= 1.0 { return "Goal crushed! You're unstoppable! 🏆" }
        if f >= 0.7 { return "Almost there! Keep it up! 🚀" }
        if f >= 0.4 { return "Halfway done, keep going! 💪" }
        return "Let's get started! You've got this! ⚡"
    }

    var body: some View {
        ZStack {
            DottedBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Header
                    HStack {
                        Text("Goals & Stats")
                            .font(.caveatBold(34))
                            .foregroundColor(.textPrimary)
                        Text("🎯").font(.system(size: 26))
                        Spacer()
                    }

                    // Weekly Goal Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Goal")
                            .font(.caveat(22, weight: .bold))
                            .foregroundColor(.textPrimary)

                        HStack {
                            Text("Solve \(store.weeklyGoal) problems")
                                .font(.caveat(17))
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text("\(store.weeklyProgress)/\(store.weeklyGoal)")
                                .font(.caveat(17, weight: .bold))
                                .foregroundColor(.textPrimary)
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.tagBackground)
                                    .frame(height: 12)
                                    .overlay(RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.sketchBorder, lineWidth: 1.5))
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.textPrimary)
                                    .frame(width: geo.size.width * progressFraction, height: 12)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progressFraction)
                            }
                        }
                        .frame(height: 12)

                        Text(motivationText)
                            .font(.caveat(15))
                            .foregroundColor(.textPrimary.opacity(0.6))
                            .italic()

                        // Goal stepper
                        HStack {
                            Text("Change goal:")
                                .font(.caveat(15))
                                .foregroundColor(.textPrimary.opacity(0.6))
                            Spacer()
                            Stepper("\(store.weeklyGoal)",
                                    value: Binding(
                                        get: { store.weeklyGoal },
                                        set: { store.weeklyGoal = $0; store.saveWeeklyGoal() }
                                    ),
                                    in: 1...50)
                            .font(.caveat(16, weight: .bold))
                        }
                    }
                    .sketchCard()

                    // Stats Row
                    HStack(spacing: 16) {
                        // Streak
                        VStack(spacing: 8) {
                            Text("🔥").font(.system(size: 34))
                            Text("\(store.streak)")
                                .font(.caveatBold(36))
                                .foregroundColor(.textPrimary)
                            Text("Day Streak")
                                .font(.caveat(15))
                                .foregroundColor(.textPrimary.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .sketchCard()

                        // Total Solved
                        VStack(spacing: 8) {
                            Text("🧠").font(.system(size: 34))
                            Text("\(store.myEntries.count)")
                                .font(.caveatBold(36))
                                .foregroundColor(.textPrimary)
                            Text("Total Solved")
                                .font(.caveat(15))
                                .foregroundColor(.textPrimary.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .sketchCard()
                    }

                    // You vs Buddy (only when connected)
                    if store.isConnected {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("\(myName) vs \(buddyName)")
                                .font(.caveat(22, weight: .bold))
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .center)

                            VsBar(label: "Easy",
                                  youLabel: myName, buddyLabel: buddyName,
                                  youCount: youEasy, buddyCount: buddyEasy)
                            VsBar(label: "Medium",
                                  youLabel: myName, buddyLabel: buddyName,
                                  youCount: youMedium, buddyCount: buddyMedium)
                            VsBar(label: "Hard",
                                  youLabel: myName, buddyLabel: buddyName,
                                  youCount: youHard, buddyCount: buddyHard)
                        }
                        .sketchCard()
                    }

                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 20)
                .padding(.top, 1)
            }
        }
    }
}

// MARK: - VS Bar Component
struct VsBar: View {
    let label: String
    let youLabel: String
    let buddyLabel: String
    let youCount: Int
    let buddyCount: Int

    var total: Int { youCount + buddyCount }
    var youFraction: Double { total > 0 ? Double(youCount) / Double(total) : 0.5 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caveat(16, weight: .bold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(youLabel): \(youCount)  \(buddyLabel): \(buddyCount)")
                    .font(.caveat(13))
                    .foregroundColor(.textPrimary.opacity(0.6))
            }

            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.userBlue)
                        .frame(width: max(geo.size.width * youFraction - 1, 0), height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.buddyPink)
                        .frame(width: max(geo.size.width * (1 - youFraction) - 1, 0), height: 16)
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.sketchBorder.opacity(0.3), lineWidth: 1))
            }
            .frame(height: 16)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: youFraction)
        }
    }
}

#Preview {
    GoalsView().environmentObject(DataStore.shared)
}

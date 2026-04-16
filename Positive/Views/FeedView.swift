
import SwiftUI

struct FeedView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedFilter: FeedFilter = .all
    @State private var selectedEntry: LCEntry? = nil
    @State private var editingEntry: LCEntry? = nil
    @State private var searchText: String = ""
    @State private var isSearchFocused: Bool = false

    enum FeedFilter: String, CaseIterable {
        case all   = "All"
        case you   = "Me"
        case buddy = "Buddy"
    }

    var myName: String    { store.myProfile?.displayName ?? "Me" }
    var buddyName: String { store.buddyProfile?.displayName ?? "Buddy" }

    // Base list from filter tab
    private var baseEntries: [LCEntry] {
        switch selectedFilter {
        case .all:   return store.entries
        case .you:   return store.myEntries
        case .buddy: return store.buddyEntries
        }
    }

    // Apply search on top of the filter
    var filteredEntries: [LCEntry] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return baseEntries }
        return baseEntries.filter { entry in
            // Problem name
            entry.problemName.lowercased().contains(q) ||
            // Difficulty (easy / medium / hard)
            entry.difficulty.rawValue.lowercased().contains(q) ||
            // Topics / categories
            entry.categories.contains(where: { $0.rawValue.lowercased().contains(q) }) ||
            // LC number as string
            String(entry.lcNumber).contains(q)
        }
    }

    var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            DottedBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    // Header
                    HStack {
                        Text("Activity Feed")
                            .font(.caveatBold(34))
                            .foregroundColor(.textPrimary)
                        Text("📝").font(.system(size: 26))
                        Spacer()
                    }

                    // ── Search Bar ──────────────────────────────────────
                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(isSearchFocused
                                                 ? Color.textPrimary
                                                 : Color.textPrimary.opacity(0.4))
                                .animation(.easeInOut(duration: 0.15), value: isSearchFocused)

                            TextField("Search by name, difficulty, topic…", text: $searchText,
                                      onEditingChanged: { isSearchFocused = $0 })
                                .font(.sketch(15))
                                .foregroundColor(.textPrimary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            if isSearching {
                                Button {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        searchText = ""
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 15))
                                        .foregroundColor(.textPrimary.opacity(0.35))
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isSearchFocused
                                    ? Color.sketchBorder
                                    : Color.sketchBorder.opacity(0.45),
                                    lineWidth: isSearchFocused ? 2 : 1.5
                                )
                                .animation(.easeInOut(duration: 0.15), value: isSearchFocused)
                        )
                        .shadow(color: isSearchFocused
                                ? Color.sketchBorder.opacity(0.08)
                                : .clear,
                                radius: 0, x: 2, y: 3)
                    }

                    // ── Filter Tabs ─────────────────────────────────────
                    HStack(spacing: 10) {
                        ForEach(FeedFilter.allCases, id: \.self) { filter in
                            if filter == .buddy && !store.isConnected { EmptyView() }
                            else {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedFilter = filter
                                    }
                                } label: {
                                    Text(label(for: filter))
                                        .font(.caveat(18, weight: .bold))
                                        .foregroundColor(selectedFilter == filter ? .white : .textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selectedFilter == filter ? Color.textPrimary : Color.cardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.sketchBorder, lineWidth: 1.5)
                                        )
                                }
                            }
                        }
                    }

                    // Result count when searching
                    if isSearching {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 13))
                                .foregroundColor(.textPrimary.opacity(0.4))
                            Text(filteredEntries.isEmpty
                                 ? "No results for \"\(searchText)\""
                                 : "\(filteredEntries.count) result\(filteredEntries.count == 1 ? "" : "s") for \"\(searchText)\"")
                                .font(.caveat(14))
                                .foregroundColor(.textPrimary.opacity(0.5))
                        }
                        .transition(.opacity)
                    }

                    // ── Feed Cards ──────────────────────────────────────
                    if filteredEntries.isEmpty {
                        VStack(spacing: 12) {
                            Text(isSearching ? "🔍" : "📭")
                                .font(.system(size: 40))
                            Text(isSearching
                                 ? "No matches found"
                                 : "No entries yet!")
                                .font(.caveat(22, weight: .bold))
                                .foregroundColor(.textPrimary)
                            Text(isSearching
                                 ? "Try a different name, topic or difficulty"
                                 : "Solve a problem and add it 💪")
                                .font(.caveat(16))
                                .foregroundColor(.textPrimary.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        .transition(.opacity)
                    } else {
                        ForEach(filteredEntries) { entry in
                            FeedCard(
                                entry: entry,
                                myName: myName,
                                buddyName: buddyName,
                                onTap: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedEntry = entry
                                    }
                                },
                                onEdit: entry.user == .you ? {
                                    editingEntry = entry
                                } : nil,
                                onDelete: entry.user == .you ? {
                                    store.deleteEntry(id: entry.id)
                                } : nil
                            )
                        }
                    }

                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 20)
                .padding(.top, 1)
                .animation(.easeInOut(duration: 0.2), value: filteredEntries.count)
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
        .sheet(item: $editingEntry) { entry in
            AddQuestionView(
                isPresented: Binding(
                    get: { editingEntry != nil },
                    set: { if !$0 { editingEntry = nil } }
                ),
                editingEntry: entry
            )
            .environmentObject(store)
        }
    }

    private func label(for filter: FeedFilter) -> String {
        switch filter {
        case .all:   return "All"
        case .you:   return myName
        case .buddy: return buddyName
        }
    }
}

// MARK: - Entry Detail Overlay

struct EntryDetailOverlay: View {
    let entry: LCEntry
    let myName: String
    let buddyName: String
    let onDismiss: () -> Void

    var displayName: String { entry.user == .you ? myName : buddyName }
    var dotColor: Color     { entry.user == .you ? .userBlue : .buddyPink }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .long
        return f.string(from: entry.date)
    }

    var body: some View {
        ZStack {
            // Dimmed scrim — tap anywhere to dismiss
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Popup card
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    // Close button
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.textPrimary.opacity(0.45))
                        }
                    }

                    // Avatar + name + date
                    HStack(spacing: 10) {
                        Circle()
                            .fill(dotColor)
                            .frame(width: 42, height: 42)
                            .overlay(
                                Text(String(displayName.prefix(1)).uppercased())
                                    .font(.caveatBold(18))
                                    .foregroundColor(.white)
                            )
                            .overlay(Circle().stroke(Color.sketchBorder, lineWidth: 1.5))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName)
                                .font(.caveat(17, weight: .bold))
                                .foregroundColor(.textPrimary)
                            Text(formattedDate)
                                .font(.caveat(14))
                                .foregroundColor(.textPrimary.opacity(0.5))
                        }
                        Spacer()
                        DifficultyBadge(difficulty: entry.difficulty)
                    }

                    Divider()
                        .overlay(Color.sketchBorder.opacity(0.35))

                    // Problem number + name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PROBLEM")
                            .font(.caveat(12))
                            .foregroundColor(.textPrimary.opacity(0.4))
                            .kerning(1.2)
                        Text("#\(entry.lcNumber)  \(entry.problemName)")
                            .font(.caveatBold(24))
                            .foregroundColor(.textPrimary)
                    }

                    // Topics / Categories
                    if !entry.categories.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TOPICS")
                                .font(.caveat(12))
                                .foregroundColor(.textPrimary.opacity(0.4))
                                .kerning(1.2)
                            FlowTagLayout(spacing: 6) {
                                ForEach(entry.categories, id: \.self) { cat in
                                    CategoryTag(category: cat)
                                }
                            }
                        }
                    }

                    // Approach
                    if !entry.approach.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("APPROACH")
                                .font(.caveat(12))
                                .foregroundColor(.textPrimary.opacity(0.4))
                                .kerning(1.2)
                            Text(entry.approach)
                                .font(.caveat(16))
                                .foregroundColor(.textPrimary.opacity(0.85))
                                .italic()
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.tagBackground.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.sketchBorder.opacity(0.35), lineWidth: 1)
                                )
                        }
                    }

                    // Complexity
                    if !entry.timeComplexity.isEmpty || !entry.spaceComplexity.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("COMPLEXITY")
                                .font(.caveat(12))
                                .foregroundColor(.textPrimary.opacity(0.4))
                                .kerning(1.2)
                            HStack(spacing: 12) {
                                if !entry.timeComplexity.isEmpty {
                                    ComplexityPill(icon: "clock", label: "Time", value: entry.timeComplexity)
                                }
                                if !entry.spaceComplexity.isEmpty {
                                    ComplexityPill(icon: "memorychip", label: "Space", value: entry.spaceComplexity)
                                }
                            }
                        }
                    }
                }
                .padding(22)
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.72)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.sketchBorder, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.2), radius: 28, x: 0, y: 10)
            .padding(.horizontal, 18)
        }
    }
}

// MARK: - Complexity Pill

private struct ComplexityPill: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.textPrimary.opacity(0.55))
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caveat(12))
                    .foregroundColor(.textPrimary.opacity(0.45))
                Text(value)
                    .font(.caveat(15, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.tagBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.sketchBorder.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Flow Tag Layout (wrapping row of tags)

private struct FlowTagLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var totalHeight: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                totalHeight += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Feed Card

struct FeedCard: View {
    let entry: LCEntry
    let myName: String
    let buddyName: String
    let onTap: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?

    var displayName: String { entry.user == .you ? myName : buddyName }
    var dotColor: Color     { entry.user == .you ? .userBlue : .buddyPink }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 12) {
                    // Top row: avatar + name + date + difficulty
                    HStack {
                        Circle()
                            .fill(dotColor)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text(String(displayName.prefix(1)).uppercased())
                                    .font(.caveatBold(14))
                                    .foregroundColor(.white)
                            )
                            .overlay(Circle().stroke(Color.sketchBorder, lineWidth: 1.2))

                        Text(displayName)
                            .font(.caveat(16, weight: .bold))
                        Text(formattedDate)
                            .font(.caveat(14))
                            .foregroundColor(.textPrimary.opacity(0.5))
                        Spacer()
                        DifficultyBadge(difficulty: entry.difficulty)
                    }

                    // Problem name
                    Text("\(entry.lcNumber). \(entry.problemName)")
                        .font(.caveat(20, weight: .bold))
                        .foregroundColor(.textPrimary)

                    // Categories
                    HStack(spacing: 6) {
                        ForEach(entry.categories, id: \.self) { cat in
                            CategoryTag(category: cat)
                        }
                    }

                    // Approach note
                    if !entry.approach.isEmpty {
                        Text(entry.approach)
                            .font(.caveat(15))
                            .foregroundColor(.textPrimary.opacity(0.75))
                            .italic()
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.tagBackground.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.sketchBorder.opacity(0.3), lineWidth: 1))
                    }

                    // Complexity
                    if !entry.timeComplexity.isEmpty || !entry.spaceComplexity.isEmpty {
                        HStack(spacing: 16) {
                            if !entry.timeComplexity.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock").font(.caption)
                                    Text(entry.timeComplexity).font(.caveat(14))
                                }
                                .foregroundColor(.textPrimary.opacity(0.6))
                            }
                            if !entry.spaceComplexity.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "memorychip").font(.caption)
                                    Text(entry.spaceComplexity).font(.caveat(14))
                                }
                                .foregroundColor(.textPrimary.opacity(0.6))
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            if let onEdit, let onDelete {
                HStack(spacing: 10) {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                            .font(.caveat(14, weight: .bold))
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.userBlue.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                            .font(.caveat(14, weight: .bold))
                            .foregroundColor(.hardRed)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.hardRed.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
            }
        }
        .sketchCard()
    }
}

#Preview {
    FeedView().environmentObject(DataStore.shared)
}

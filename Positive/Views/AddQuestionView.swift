
import SwiftUI

struct AddQuestionView: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool
    let editingEntry: LCEntry?

    @State private var lcNumber: String         = ""
    @State private var problemName: String      = ""
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var selectedCategories: Set<Category> = []
    @State private var approach: String         = ""
    @State private var timeComplexity: String   = ""
    @State private var spaceComplexity: String  = ""
    @State private var showValidationAlert = false

    var canSave: Bool {
        !lcNumber.isEmpty && !problemName.isEmpty && Int(lcNumber) != nil
    }

    var body: some View {
        ZStack {
            DottedBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    HStack {
                        Text(editingEntry == nil ? "Add Question ✏️" : "Edit Question ✏️")
                            .font(.caveatBold(28))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button { isPresented = false } label: {
                            Text("✕")
                                .font(.caveat(22, weight: .bold))
                                .foregroundColor(.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(Color.cardBackground)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.sketchBorder, lineWidth: 1.5))
                        }
                    }
                    .padding(.top, 8)

                    Divider()
                        .overlay(Color.sketchBorder.opacity(0.3))
                        .padding(.bottom, 4)

                    // LC Number & Problem Name
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("LC Number")
                                .font(.caveat(16, weight: .bold))
                                .foregroundColor(.textPrimary)
                            TextField("e.g. 1", text: $lcNumber)
                                .font(.caveat(17))
                                .keyboardType(.numberPad)
                                .sketchTextField()
                        }
                        .frame(maxWidth: 110)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Problem Name")
                                .font(.caveat(16, weight: .bold))
                                .foregroundColor(.textPrimary)
                            TextField("e.g. Two Sum", text: $problemName)
                                .font(.caveat(17))
                                .sketchTextField()
                        }
                    }

                    // Difficulty
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Difficulty")
                            .font(.caveat(18, weight: .bold))
                            .foregroundColor(.textPrimary)
                        HStack(spacing: 10) {
                            ForEach(Difficulty.allCases, id: \.self) { diff in
                                Button { selectedDifficulty = diff } label: {
                                    Text(diff.rawValue)
                                        .font(.caveat(17, weight: .bold))
                                        .foregroundColor(.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selectedDifficulty == diff ? diffColor(diff) : Color.cardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.sketchBorder, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }

                    // Categories
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Categories (Max 3)")
                            .font(.caveat(18, weight: .bold))
                            .foregroundColor(.textPrimary)
                        WrappingHStack(categories: Category.allCases, selected: $selectedCategories)
                    }

                    // Approach
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Approach")
                            .font(.caveat(18, weight: .bold))
                            .foregroundColor(.textPrimary)
                        ZStack(alignment: .topLeading) {
                            if approach.isEmpty {
                                Text("How did you solve it? What was the trick?")
                                    .font(.caveat(16))
                                    .foregroundColor(.textPrimary.opacity(0.35))
                                    .padding(.horizontal, 12)
                                    .padding(.top, 12)
                            }
                            TextEditor(text: $approach)
                                .font(.caveat(16))
                                .foregroundColor(.textPrimary)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                        }
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.sketchBorder, lineWidth: 2))
                    }

                    // Complexity (optional)
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Time Complexity")
                                .font(.caveat(14, weight: .bold))
                                .foregroundColor(.textPrimary)
                            TextField("e.g. O(n)", text: $timeComplexity)
                                .font(.caveat(16))
                                .sketchTextField()
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Space Complexity")
                                .font(.caveat(14, weight: .bold))
                                .foregroundColor(.textPrimary)
                            TextField("e.g. O(1)", text: $spaceComplexity)
                                .font(.caveat(16))
                                .sketchTextField()
                        }
                    }

                    // Save Button
                    Button { saveEntry() } label: {
                        Text(editingEntry == nil ? "Save Note 💾" : "Save Changes 💾")
                            .font(.caveat(22, weight: .bold))
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(SketchButtonStyle(fillColor: canSave ? .accentYellow : Color.tagBackground))
                    .disabled(!canSave)
                    .padding(.top, 8)

                    if editingEntry != nil {
                        Button(role: .destructive) { deleteEntry() } label: {
                            Text("Delete Problem 🗑️")
                                .font(.caveat(20, weight: .bold))
                                .foregroundColor(.hardRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(SketchButtonStyle(fillColor: Color.hardRed.opacity(0.12)))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .alert("Missing Info", isPresented: $showValidationAlert) {
            Button("OK") {}
        } message: {
            Text("Please enter a valid LC number and problem name.")
        }
        .onAppear {
            guard let editingEntry else { return }
            lcNumber = String(editingEntry.lcNumber)
            problemName = editingEntry.problemName
            selectedDifficulty = editingEntry.difficulty
            selectedCategories = Set(editingEntry.categories)
            approach = editingEntry.approach
            timeComplexity = editingEntry.timeComplexity
            spaceComplexity = editingEntry.spaceComplexity
        }
    }

    private func diffColor(_ d: Difficulty) -> Color {
        switch d {
        case .easy:   return .easyGreen
        case .medium: return .mediumYellow
        case .hard:   return .hardRed
        }
    }

    private func saveEntry() {
        guard canSave, let num = Int(lcNumber) else {
            showValidationAlert = true
            return
        }
        if var existing = editingEntry {
            existing.lcNumber = num
            existing.problemName = problemName
            existing.difficulty = selectedDifficulty
            existing.categories = Array(selectedCategories)
            existing.approach = approach
            existing.timeComplexity = timeComplexity
            existing.spaceComplexity = spaceComplexity
            store.updateEntry(existing)
        } else {
            // ownerUID and user are set inside DataStore.addEntry
            let entry = LCEntry(
                lcNumber: num,
                problemName: problemName,
                difficulty: selectedDifficulty,
                categories: Array(selectedCategories),
                approach: approach,
                timeComplexity: timeComplexity,
                spaceComplexity: spaceComplexity,
                user: .you,
                date: Date(),
                ownerUID: ""   // filled in by DataStore
            )
            store.addEntry(entry)
        }
        isPresented = false
    }

    private func deleteEntry() {
        guard let editingEntry else { return }
        store.deleteEntry(id: editingEntry.id)
        isPresented = false
    }
}

// MARK: - Wrapping HStack for categories
struct WrappingHStack: View {
    let categories: [Category]
    @Binding var selected: Set<Category>

    var body: some View {
        let rows = makeRows()
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { cat in
                        Button {
                            if selected.contains(cat) {
                                selected.remove(cat)
                            } else if selected.count < 3 {
                                selected.insert(cat)
                            }
                        } label: {
                            Text(cat.rawValue)
                                .font(.caveat(15))
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selected.contains(cat) ? Color.userBlue.opacity(0.6) : Color.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.sketchBorder, lineWidth: 1.5))
                        }
                    }
                }
            }
        }
    }

    private func makeRows() -> [[Category]] {
        var rows: [[Category]] = []
        var current: [Category] = []
        for (i, cat) in categories.enumerated() {
            current.append(cat)
            if current.count == 3 || i == categories.count - 1 {
                rows.append(current)
                current = []
            }
        }
        return rows
    }
}

#Preview {
    AddQuestionView(isPresented: .constant(true), editingEntry: nil)
        .environmentObject(DataStore.shared)
}

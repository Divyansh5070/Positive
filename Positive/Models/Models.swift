
import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

// MARK: - Difficulty
enum Difficulty: String, Codable, CaseIterable, Sendable {
    case easy   = "Easy"
    case medium = "Medium"
    case hard   = "Hard"
}

// MARK: - Category
enu\m Category: String, Codable, CaseIterable, Sendable, Hashable {
    case array        = "Array"
    case string       = "String"
    case hashTable    = "Hash Table"
    case dp           = "Dynamic Programming"
    case math         = "Math"
    case sorting      = "Sorting"
    case greedy       = "Greedy"
    case dfs          = "DFS"
    case database     = "Database"
    case bfs          = "BFS"
    case tree         = "Tree"
    case binarySearch = "Binary Search"
}

// MARK: - User Identity (display role)
enum UserIdentity: String, Codable, CaseIterable, Sendable {
    case you   = "You"
    case buddy = "Buddy"

    var initial: String {
        switch self {
        case .you:   return "Y"
        case .buddy: return "B"
        }
    }
}

enum TodoTag: String, Codable, CaseIterable, Sendable {
    case leetcode = "Leetcode"
    case academic = "Academic"
    case development = "Development"
    case other = "Other"
}

// MARK: - Todo Item
struct TodoItem: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool
    var tag: TodoTag?
    var user: UserIdentity
    var date: Date
    var ownerUID: String

    var dateKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// MARK: - User Profile (Firestore document at users/{uid})
struct UserProfile: Identifiable {
    let id: String        // Firebase UID
    var displayName: String
    var email: String
    var buddyUID: String?    // nil = solo mode
    var buddyCode: String    // short code for connecting (first 6 of UID)

    /// Firestore → UserProfile
    init?(uid: String, data: [String: Any]) {
        guard let name = data["displayName"] as? String else { return nil }
        self.id          = uid
        self.displayName = name
        self.email       = data["email"] as? String ?? ""
        self.buddyUID    = data["buddyUID"] as? String
        self.buddyCode   = data["buddyCode"] as? String ?? String(uid.prefix(6)).uppercased()
    }

    /// UserProfile → Firestore
    func toFirestoreData() -> [String: Any] {
        var dict: [String: Any] = [
            "displayName": displayName,
            "email": email,
            "buddyCode": buddyCode
        ]
        if let b = buddyUID { dict["buddyUID"] = b }
        return dict
    }
}

// MARK: - LeetCode Entry
struct LCEntry: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var lcNumber: Int
    var problemName: String
    var difficulty: Difficulty
    var categories: [Category]
    var approach: String
    var timeComplexity: String
    var spaceComplexity: String
    // `user` is computed from whose subcollection the entry lives in,
    // but stored here for convenience when merging your + buddy entries.
    var user: UserIdentity
    var date: Date
    var ownerUID: String      // which user owns this entry

    var dateKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// MARK: - Firestore ↔ LCEntry
extension LCEntry {

    func toFirestoreData() -> [String: Any] {
        [
            "id":              id.uuidString,
            "lcNumber":        lcNumber,
            "problemName":     problemName,
            "difficulty":      difficulty.rawValue,
            "categories":      categories.map { $0.rawValue },
            "approach":        approach,
            "timeComplexity":  timeComplexity,
            "spaceComplexity": spaceComplexity,
            "user":            user.rawValue,
            "date":            Timestamp(date: date),
            "ownerUID":        ownerUID
        ]
    }

    init?(from data: [String: Any], id docID: String, role: UserIdentity) {
        guard
            let idStr       = data["id"] as? String,
            let id          = UUID(uuidString: idStr),
            let lcNumber    = data["lcNumber"] as? Int,
            let problemName = data["problemName"] as? String,
            let diffRaw     = data["difficulty"] as? String,
            let difficulty  = Difficulty(rawValue: diffRaw),
            let catRaws     = data["categories"] as? [String],
            let ts          = data["date"] as? Timestamp
        else { return nil }

        self.id              = id
        self.lcNumber        = lcNumber
        self.problemName     = problemName
        self.difficulty      = difficulty
        self.categories      = catRaws.compactMap { Category(rawValue: $0) }
        self.approach        = data["approach"] as? String ?? ""
        self.timeComplexity  = data["timeComplexity"] as? String ?? ""
        self.spaceComplexity = data["spaceComplexity"] as? String ?? ""
        self.user            = role          // role = .you or .buddy based on whose collection
        self.date            = ts.dateValue()
        self.ownerUID        = data["ownerUID"] as? String ?? ""
    }
}

// MARK: - Firestore ↔ TodoItem
extension TodoItem {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "isCompleted": isCompleted,
            "user": user.rawValue,
            "date": Timestamp(date: date),
            "ownerUID": ownerUID
        ]
        if let tag {
            data["tag"] = tag.rawValue
        }
        return data
    }

    init?(from data: [String: Any], role: UserIdentity) {
        guard
            let idStr = data["id"] as? String,
            let id = UUID(uuidString: idStr),
            let title = data["title"] as? String,
            let isCompleted = data["isCompleted"] as? Bool,
            let ts = data["date"] as? Timestamp
        else { return nil }

        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.tag = (data["tag"] as? String).flatMap { TodoTag(rawValue: $0) } ?? Self.legacyTag(from: data["difficulty"] as? String)
        self.user = role
        self.date = ts.dateValue()
        self.ownerUID = data["ownerUID"] as? String ?? ""
    }

    private static func legacyTag(from oldDifficulty: String?) -> TodoTag? {
        guard let oldDifficulty else { return nil }
        switch oldDifficulty.lowercased() {
        case "easy", "medium", "hard":
            return .leetcode
        default:
            return nil
        }
    }
}

// MARK: - Data Store (Firestore-backed, per-user + optional buddy)
@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var myEntries: [LCEntry]    = []
    @Published var buddyEntries: [LCEntry] = []
    @Published var myTodos: [TodoItem] = []
    @Published var buddyTodos: [TodoItem] = []
    /// Pre-merged + sorted; updated only when sources change, not on every render.
    @Published private(set) var entries: [LCEntry] = []

    @Published var myProfile: UserProfile? = nil
    @Published var buddyProfile: UserProfile? = nil
    @Published var weeklyGoal: Int         = 10
    @Published var isLoading: Bool         = true

    private let goalKey = "weekly_goal"
    private var myListener: ListenerRegistration?
    private var buddyListener: ListenerRegistration?
    private var myTodoListener: ListenerRegistration?
    private var buddyTodoListener: ListenerRegistration?
    private var profileListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    /// Shared date formatter — allocated once, never recreated.
    private static let dayFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private init() {
        weeklyGoal = UserDefaults.standard.integer(forKey: goalKey)
        if weeklyGoal == 0 { weeklyGoal = 10 }

        // Rebuild `entries` only when either source array actually changes.
        Publishers.CombineLatest($myEntries, $buddyEntries)
            .map { mine, buddy in (mine + buddy).sorted { $0.date > $1.date } }
            .receive(on: RunLoop.main)
            .assign(to: &$entries)
    }

    deinit {
        myListener?.remove()
        buddyListener?.remove()
        myTodoListener?.remove()
        buddyTodoListener?.remove()
        profileListener?.remove()
    }

    // MARK: - Start listening (call after sign-in)
    func startListening(uid: String) {
        myListener?.remove()
        myTodoListener?.remove()
        listenToMyEntries(uid: uid)
        listenToMyTodos(uid: uid)
        listenToProfile(uid: uid)
    }

    func stopListening() {
        myListener?.remove()
        buddyListener?.remove()
        myTodoListener?.remove()
        buddyTodoListener?.remove()
        profileListener?.remove()
        myEntries    = []
        buddyEntries = []
        myTodos = []
        buddyTodos = []
        myProfile    = nil
        buddyProfile = nil
        isLoading    = true
    }

    // MARK: - Profile listener
    private func listenToProfile(uid: String) {
        profileListener?.remove()
        profileListener = FirebaseService.shared.listenToProfile(uid: uid) { [weak self] profile in
            Task { @MainActor in
                self?.myProfile = profile
                // React to buddy changes
                let newBuddyUID = profile?.buddyUID
                let oldBuddyUID = self?.buddyProfile?.id
                if newBuddyUID != oldBuddyUID {
                    if let bUID = newBuddyUID {
                        self?.listenToBuddyEntries(buddyUID: bUID)
                        self?.listenToBuddyTodos(buddyUID: bUID)
                        // Fetch buddy profile once
                        Task {
                            self?.buddyProfile = try? await FirebaseService.shared.fetchProfile(uid: bUID)
                        }
                    } else {
                        self?.buddyListener?.remove()
                        self?.buddyTodoListener?.remove()
                        self?.buddyEntries  = []
                        self?.buddyTodos = []
                        self?.buddyProfile  = nil
                    }
                }
            }
        }
    }

    // MARK: - My entries listener
    private func listenToMyEntries(uid: String) {
        myListener?.remove()
        myListener = FirebaseService.shared.listenToEntries(ownerUID: uid, role: .you) { [weak self] entries in
            Task { @MainActor in
                self?.myEntries = entries
                self?.isLoading = false
            }
        }
    }

    // MARK: - Buddy entries listener
    private func listenToBuddyEntries(buddyUID: String) {
        buddyListener?.remove()
        buddyListener = FirebaseService.shared.listenToEntries(ownerUID: buddyUID, role: .buddy) { [weak self] entries in
            Task { @MainActor in
                self?.buddyEntries = entries
            }
        }
    }

    // MARK: - Todo listeners
    private func listenToMyTodos(uid: String) {
        myTodoListener?.remove()
        myTodoListener = FirebaseService.shared.listenToTodos(ownerUID: uid, role: .you) { [weak self] todos in
            Task { @MainActor in
                self?.myTodos = todos
            }
        }
    }

    private func listenToBuddyTodos(buddyUID: String) {
        buddyTodoListener?.remove()
        buddyTodoListener = FirebaseService.shared.listenToTodos(ownerUID: buddyUID, role: .buddy) { [weak self] todos in
            Task { @MainActor in
                self?.buddyTodos = todos
            }
        }
    }

    // MARK: - Write operations
    func addEntry(_ entry: LCEntry) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var e = entry
        e.ownerUID = uid
        e.user = .you
        Task { try? await FirebaseService.shared.addEntry(e, ownerUID: uid) }
    }

    func updateEntry(_ entry: LCEntry) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var e = entry
        e.ownerUID = uid
        e.user = .you
        Task { try? await FirebaseService.shared.updateEntry(e, ownerUID: uid) }
    }

    func deleteEntry(id: UUID) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task { try? await FirebaseService.shared.deleteEntry(id: id, ownerUID: uid) }
    }

    func addTodo(_ todo: TodoItem) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var item = todo
        item.ownerUID = uid
        item.user = .you
        item.date = Calendar.current.startOfDay(for: item.date)
        Task { try? await FirebaseService.shared.addTodo(item, ownerUID: uid) }
    }

    func toggleTodoCompletion(id: UUID, isCompleted: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task { try? await FirebaseService.shared.updateTodoCompletion(id: id, ownerUID: uid, isCompleted: isCompleted) }
    }

    func deleteTodo(id: UUID) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task { try? await FirebaseService.shared.deleteTodo(id: id, ownerUID: uid) }
    }

    func saveWeeklyGoal() {
        UserDefaults.standard.set(weeklyGoal, forKey: goalKey)
    }

    // MARK: - Buddy connection
    func connectToBuddy(code: String) async throws {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        try await FirebaseService.shared.connectBuddy(myUID: myUID, buddyCode: code)
    }

    func disconnectBuddy() async throws {
        guard let myUID = Auth.auth().currentUser?.uid,
              let buddyUID = myProfile?.buddyUID else { return }
        try await FirebaseService.shared.disconnectBuddy(myUID: myUID, buddyUID: buddyUID)
    }

    // MARK: - Computed properties
    var todayKey: String { DataStore.dayFmt.string(from: Date()) }

    var todayEntries: [LCEntry] { entries.filter { $0.dateKey == todayKey } }
    var youTodayCount: Int   { myEntries.filter { $0.dateKey == todayKey }.count }
    var buddyTodayCount: Int { buddyEntries.filter { $0.dateKey == todayKey }.count }
    var isConnected: Bool    { myProfile?.buddyUID != nil }

    /// O(n) streak — builds a Set once, then walks backwards day by day.
    var streak: Int {
        let keySet = Set(myEntries.map { $0.dateKey })
        let cal    = Calendar.current
        var count  = 0
        var d      = Date()
        while keySet.contains(DataStore.dayFmt.string(from: d)) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
        }
        return count
    }

    var weeklyProgress: Int {
        let cal   = Calendar.current
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return myEntries.filter { $0.date >= start }.count
    }

    func entriesBy(user: UserIdentity, difficulty: Difficulty) -> Int {
        let src = user == .you ? myEntries : buddyEntries
        return src.filter { $0.difficulty == difficulty }.count
    }

    func datesWithEntries(for user: UserIdentity, in month: Date) -> Set<String> {
        let cal = Calendar.current
        let c   = cal.dateComponents([.year, .month], from: month)
        let src = user == .you ? myEntries : buddyEntries
        return Set(src.filter {
            cal.component(.year,  from: $0.date) == c.year &&
            cal.component(.month, from: $0.date) == c.month
        }.map { DataStore.dayFmt.string(from: $0.date) })
    }

    var todayMyTodos: [TodoItem] {
        myTodos.filter { $0.dateKey == todayKey }.sorted { $0.date > $1.date }
    }

    var todayBuddyTodos: [TodoItem] {
        buddyTodos.filter { $0.dateKey == todayKey }.sorted { $0.date > $1.date }
    }

    var todayTodos: [TodoItem] {
        (todayMyTodos + todayBuddyTodos).sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            return lhs.date > rhs.date
        }
    }

    var remainingTodayTodoCount: Int {
        todayTodos.filter { !$0.isCompleted }.count
    }
}

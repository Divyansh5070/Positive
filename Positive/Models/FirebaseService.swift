
import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - FirebaseService
// All Firestore I/O. Entries are stored at users/{uid}/entries/{entryId}.
// User profiles are stored at users/{uid}.

final class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Entry paths
    private func entriesRef(for uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("entries")
    }

    private func todosRef(for uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("todos")
    }

    // MARK: - Add / update entry
    func addEntry(_ entry: LCEntry, ownerUID: String) async throws {
        let doc = entriesRef(for: ownerUID).document(entry.id.uuidString)
        try await doc.setData(entry.toFirestoreData())
    }

    func updateEntry(_ entry: LCEntry, ownerUID: String) async throws {
        let doc = entriesRef(for: ownerUID).document(entry.id.uuidString)
        try await doc.setData(entry.toFirestoreData(), merge: true)
    }

    // MARK: - Delete entry
    func deleteEntry(id: UUID, ownerUID: String) async throws {
        try await entriesRef(for: ownerUID).document(id.uuidString).delete()
    }

    // MARK: - Todo operations
    func addTodo(_ todo: TodoItem, ownerUID: String) async throws {
        let doc = todosRef(for: ownerUID).document(todo.id.uuidString)
        try await doc.setData(todo.toFirestoreData())
    }

    func updateTodoCompletion(id: UUID, ownerUID: String, isCompleted: Bool) async throws {
        try await todosRef(for: ownerUID)
            .document(id.uuidString)
            .updateData(["isCompleted": isCompleted])
    }

    func deleteTodo(id: UUID, ownerUID: String) async throws {
        try await todosRef(for: ownerUID).document(id.uuidString).delete()
    }

    // MARK: - Real-time listener for entries
    func listenToEntries(
        ownerUID: String,
        role: UserIdentity,
        onChange: @escaping ([LCEntry]) -> Void
    ) -> ListenerRegistration {
        entriesRef(for: ownerUID)
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    print("[FirebaseService] Listener error (\(ownerUID)): \(error.localizedDescription)")
                    return
                }
                guard let docs = snapshot?.documents else { return }
                let entries = docs.compactMap {
                    LCEntry(from: $0.data(), id: $0.documentID, role: role)
                }
                onChange(entries)
            }
    }

    // MARK: - Real-time listener for todos
    func listenToTodos(
        ownerUID: String,
        role: UserIdentity,
        onChange: @escaping ([TodoItem]) -> Void
    ) -> ListenerRegistration {
        todosRef(for: ownerUID)
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    print("[FirebaseService] Todo listener error (\(ownerUID)): \(error.localizedDescription)")
                    return
                }
                guard let docs = snapshot?.documents else { return }
                let todos = docs.compactMap { TodoItem(from: $0.data(), role: role) }
                onChange(todos)
            }
    }

    // MARK: - Profile helpers
    private func profileRef(uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }

    /// Create or update a user's profile document
    func createOrUpdateProfile(uid: String, displayName: String, email: String) async throws {
        let code = String(uid.prefix(6)).uppercased()
        let data: [String: Any] = [
            "displayName": displayName,
            "email": email,
            "buddyCode": code
        ]
        // merge:true so we don't wipe buddyUID if it already exists
        try await profileRef(uid: uid).setData(data, merge: true)
    }

    /// Fetch a profile once
    func fetchProfile(uid: String) async throws -> UserProfile? {
        let snap = try await profileRef(uid: uid).getDocument()
        guard let data = snap.data() else { return nil }
        return UserProfile(uid: uid, data: data)
    }

    /// Real-time listener on a user's profile
    func listenToProfile(uid: String, onChange: @escaping (UserProfile?) -> Void) -> ListenerRegistration {
        profileRef(uid: uid).addSnapshotListener { snap, error in
            if let error {
                print("[FirebaseService] Profile listener error: \(error.localizedDescription)")
                onChange(nil)
                return
            }
            guard let data = snap?.data() else { onChange(nil); return }
            onChange(UserProfile(uid: uid, data: data))
        }
    }

    // MARK: - Buddy connection
    /// Find the user with the given buddyCode and link them both
    func connectBuddy(myUID: String, buddyCode: String) async throws {
        let code = buddyCode.uppercased().trimmingCharacters(in: .whitespaces)
        let snap = try await db.collection("users")
            .whereField("buddyCode", isEqualTo: code)
            .limit(to: 1)
            .getDocuments()

        guard let buddyDoc = snap.documents.first else {
            throw BuddyError.notFound
        }
        let buddyUID = buddyDoc.documentID
        guard buddyUID != myUID else { throw BuddyError.cannotAddSelf }

        // Check they're not already connected to someone else
        if let existingBuddy = buddyDoc.data()["buddyUID"] as? String,
           !existingBuddy.isEmpty, existingBuddy != myUID {
            throw BuddyError.alreadyConnected
        }

        let batch = db.batch()
        batch.updateData(["buddyUID": buddyUID], forDocument: profileRef(uid: myUID))
        batch.updateData(["buddyUID": myUID],    forDocument: profileRef(uid: buddyUID))
        try await batch.commit()
    }

    /// Remove the buddy link from both users
    func disconnectBuddy(myUID: String, buddyUID: String) async throws {
        let batch = db.batch()
        batch.updateData(["buddyUID": FieldValue.delete()], forDocument: profileRef(uid: myUID))
        batch.updateData(["buddyUID": FieldValue.delete()], forDocument: profileRef(uid: buddyUID))
        try await batch.commit()
    }
}

// MARK: - Buddy Errors
enum BuddyError: LocalizedError {
    case notFound
    case cannotAddSelf
    case alreadyConnected

    var errorDescription: String? {
        switch self {
        case .notFound:         return "No user found with that code. Check with your buddy."
        case .cannotAddSelf:    return "That's your own code — share it with your buddy instead!"
        case .alreadyConnected: return "That user is already connected to someone else."
        }
    }
}

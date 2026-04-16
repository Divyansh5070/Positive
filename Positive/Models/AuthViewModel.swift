
import SwiftUI
import Combine
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

// MARK: - Auth State
enum AuthState {
    case loading
    case signedOut
    case signedIn(User)
}

// MARK: - AuthViewModel
@MainActor
final class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()

    @Published var authState: AuthState = .loading
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false

    private var handle: AuthStateDidChangeListenerHandle?

    private init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.authState = .signedIn(user)
                    // Create/update Firestore profile and start listening
                    try? await FirebaseService.shared.createOrUpdateProfile(
                        uid: user.uid,
                        displayName: user.displayName ?? user.email ?? "Coder",
                        email: user.email ?? ""
                    )
                    DataStore.shared.startListening(uid: user.uid)
                } else {
                    self?.authState = .signedOut
                    DataStore.shared.stopListening()
                }
            }
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    // MARK: - Email / Password Sign In
    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await Auth.auth().signIn(withEmail: email, password: password)
            } catch {
                errorMessage = friendlyError(error)
            }
            isLoading = false
        }
    }

    // MARK: - Email / Password Sign Up
    func signUp(email: String, password: String, name: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                if !name.isEmpty {
                    let changeRequest = result.user.createProfileChangeRequest()
                    changeRequest.displayName = name
                    try await changeRequest.commitChanges()
                }
            } catch {
                errorMessage = friendlyError(error)
            }
            isLoading = false
        }
    }

    // MARK: - Google Sign In
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        isLoading = true
        errorMessage = nil

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
            Task { @MainActor in
                defer { self?.isLoading = false }
                if let error {
                    self?.errorMessage = self?.friendlyError(error)
                    return
                }
                guard
                    let user       = result?.user,
                    let idToken    = user.idToken?.tokenString
                else {
                    self?.errorMessage = "Google sign-in failed. Please try again."
                    return
                }
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: user.accessToken.tokenString
                )
                do {
                    try await Auth.auth().signIn(with: credential)
                } catch {
                    self?.errorMessage = self?.friendlyError(error)
                }
            }
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            GIDSignIn.sharedInstance.signOut()
            try Auth.auth().signOut()
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    // MARK: - Password Reset
    func resetPassword(email: String) {
        guard !email.isEmpty else {
            errorMessage = "Enter your email to reset your password."
            return
        }
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                errorMessage = "✓ Reset link sent to \(email)"
            } catch {
                errorMessage = friendlyError(error)
            }
        }
    }

    // MARK: - Helpers
    private func friendlyError(_ error: Error) -> String {
        let nsErr = error as NSError
        // Firebase Auth errors have domain "FIRAuthErrorDomain"
        if nsErr.domain == AuthErrorDomain {
            switch AuthErrorCode(rawValue: nsErr.code) {
            case .wrongPassword:         return "Incorrect password. Try again."
            case .invalidEmail:          return "That doesn't look like a valid email."
            case .emailAlreadyInUse:     return "An account with this email already exists."
            case .weakPassword:          return "Choose a stronger password (min 6 chars)."
            case .userNotFound:          return "No account found with that email."
            case .networkError:          return "Network error. Check your connection."
            case .tooManyRequests:       return "Too many attempts. Please wait and retry."
            case .invalidCredential:     return "Incorrect email or password."
            default: break
            }
        }
        // Google Sign-In cancellation — don't show an error
        if nsErr.domain == "com.google.GIDSignIn" && nsErr.code == -5 {
            return ""
        }
        return error.localizedDescription
    }
}

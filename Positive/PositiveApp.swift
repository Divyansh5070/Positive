
import SwiftUI
import FirebaseCore
import GoogleSignIn
import UIKit

// MARK: - AppDelegate
// Using AppDelegate ensures FirebaseApp.configure() runs before ANY
// stored property (like DataStore.shared) tries to access Firestore.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }

    // Required for Google Sign-In to complete its OAuth flow
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - App Entry Point
@main
struct PositiveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = DataStore.shared
    @StateObject private var auth  = AuthViewModel.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(auth)
                .preferredColorScheme(.light)
        }
    }
}

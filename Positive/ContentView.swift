
import SwiftUI

// MARK: - Root Auth Gate
struct ContentView: View {
    @StateObject private var auth = AuthViewModel.shared

    var body: some View {
        switch auth.authState {
        case .loading:
            // Splash / loading state while Firebase checks auth
            ZStack {
                DottedBackground()
                VStack(spacing: 14) {
                    Text("✦")
                        .font(.system(size: 52))
                    Text("Positive")
                        .font(.sketchBold(28))
                        .foregroundColor(.textPrimary)
                    ProgressView()
                        .tint(.textPrimary)
                }
            }
        case .signedOut:
            LoginView()
        case .signedIn:
            MainTabView()
        }
    }
}

// MARK: - Main App (Tab)
struct MainTabView: View {
    @StateObject private var auth = AuthViewModel.shared
    @ObservedObject private var store = DataStore.shared
    @State private var selectedTab: Int = 0
    @State private var showAddQuestion = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content — fills the whole screen, tab bar floats on top
            ZStack {
                switch selectedTab {
                case 0: HomeView(showAddQuestion: $showAddQuestion)
                case 1: CalendarView()
                case 2: FeedView()
                case 3: GoalsView()
                default: HomeView(showAddQuestion: $showAddQuestion)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            // Reserve space at the bottom so content isn't hidden under the pill
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 130)
            }

            // Floating tab bar — overlays the content
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showAddQuestion) {
            AddQuestionView(isPresented: $showAddQuestion, editingEntry: nil)
                .environmentObject(store)
        }
        .environmentObject(store)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @State private var bounceTab: Int? = nil

    let tabs: [(icon: String, label: String)] = [
        ("house.fill",    "Home"),
        ("calendar",      "Calendar"),
        ("person.2.fill", "Feed"),
        ("flag.fill",     "Goals")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { idx in
                    TabItemView(
                        icon: tabs[idx].icon,
                        label: tabs[idx].label,
                        isSelected: selectedTab == idx,
                        isBouncing: bounceTab == idx
                    ) {
                        if selectedTab != idx {
                            bounceTab = idx
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.6)) {
                                selectedTab = idx
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                bounceTab = nil
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.sketchBorder, lineWidth: 2)
                    )
                    .shadow(color: Color.sketchBorder.opacity(0.18), radius: 0, x: 3, y: 5)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 26)
        }
    }
}

// MARK: - Tab Item View
struct TabItemView: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let isBouncing: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Inner content — background sized to fit exactly
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: isSelected ? .bold : .regular))
                        .scaleEffect(isBouncing ? 1.3 : (isSelected ? 1.08 : 1.0))
                        .animation(
                            isBouncing
                            ? .spring(response: 0.3, dampingFraction: 0.45)
                            : .spring(response: 0.35, dampingFraction: 0.65),
                            value: isBouncing
                        )
                        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)

                    Text(label)
                        .font(.sketch(10, weight: isSelected ? .bold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .multilineTextAlignment(.center)
                        .scaleEffect(isSelected ? 1.0 : 0.92)
                        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentYellow)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.sketchBorder, lineWidth: 1.5)
                                )
                                .shadow(color: Color.sketchBorder.opacity(0.18), radius: 0, x: 2, y: 3)
                                .transition(.scale(scale: 0.6).combined(with: .opacity))
                        }
                    }
                )
                .foregroundColor(
                    isSelected ? Color.textPrimary : Color.textPrimary.opacity(0.35)
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)

                // Ink dot indicator
                Circle()
                    .fill(Color.sketchBorder)
                    .frame(width: 4, height: 5)
                    .scaleEffect(isSelected ? 1.0 : 0.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.55), value: isSelected)
            }
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(isPressed ? 0.93 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    ContentView()
}

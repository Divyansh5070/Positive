
import SwiftUI

// MARK: - Login View
struct LoginView: View {
    @StateObject private var auth = AuthViewModel.shared

    @State private var mode: LoginMode = .signIn
    @State private var email: String   = ""
    @State private var password: String = ""
    @State private var name: String    = ""
    @State private var showPassword: Bool = false
    @State private var showForgot: Bool   = false
    @State private var shake: Bool = false
    @State private var floatOffset: CGFloat = 0

    enum LoginMode { case signIn, signUp }

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────
            DottedBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // ── Hero ────────────────────────────────────────
                    heroSection

                    // ── Card ────────────────────────────────────────
                    VStack(spacing: 20) {
                        modeToggle

                        if mode == .signUp {
                            nameField
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        emailField
                        passwordField

                        if mode == .signIn {
                            forgotButton
                        }

                        primaryActionButton

                        divider

                        googleButton

                        switchModeFooter
                    }
                    .padding(24)
                    .sketchCard(padding: 0)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: mode)

                    // ── Error Banner ─────────────────────────────────
                    if let msg = auth.errorMessage, !msg.isEmpty {
                        errorBanner(msg)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.top, 16)
            }

            // ── Loading overlay ──────────────────────────────────────
            if auth.isLoading {
                loadingOverlay
            }
        }
        .sheet(isPresented: $showForgot) {
            ForgotPasswordSheet(email: $email)
                .environmentObject(auth)
        }
        .onChange(of: auth.errorMessage) { _, msg in
            if msg != nil { triggerShake() }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.2)
                .repeatForever(autoreverses: true)
            ) { floatOffset = -8 }
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 8) {
            ZStack {
                // Sketch circles behind logo
                Circle()
                    .stroke(Color.accentYellow, lineWidth: 2.5)
                    .frame(width: 100, height: 100)
                    .offset(x: 4, y: 4)
                Circle()
                    .fill(Color.cardBackground)
                    .frame(width: 88, height: 88)
                    .overlay(
                        Circle().stroke(Color.sketchBorder, lineWidth: 2)
                    )
                    .shadow(color: Color.sketchBorder.opacity(0.12), radius: 6, x: 3, y: 4)
                Text("✦")
                    .font(.system(size: 42))
            }
            .offset(y: floatOffset)
            .animation(
                .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                value: floatOffset
            )
            .padding(.top, 40)
            .padding(.bottom, 4)

            Text("Positive")
                .font(.sketchBold(36))
                .foregroundColor(.textPrimary)

            Text("Track your progress together")
                .font(.sketch(15))
                .foregroundColor(.textPrimary.opacity(0.55))
                .padding(.bottom, 24)
        }
    }

    // MARK: - Mode Toggle
    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach([LoginMode.signIn, .signUp], id: \.self) { m in
                Button {
                    withAnimation { mode = m }
                    auth.errorMessage = nil
                } label: {
                    VStack(spacing: 4) {
                        Text(m == .signIn ? "Sign In" : "Create Account")
                            .font(.sketch(15, weight: mode == m ? .bold : .regular))
                            .foregroundColor(mode == m ? .textPrimary : .textPrimary.opacity(0.4))
                        Rectangle()
                            .fill(mode == m ? Color.accentYellow : Color.clear)
                            .frame(height: 2.5)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .overlay(
            Rectangle()
                .fill(Color.sketchBorder.opacity(0.15))
                .frame(height: 1),
            alignment: .bottom
        )
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    // MARK: - Fields
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Your name")
            TextField("e.g. Alex", text: $name)
                .font(.sketch(15))
                .sketchTextField()
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Email")
            TextField("you@example.com", text: $email)
                .font(.sketch(15))
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .sketchTextField()
                .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
        }
        .padding(.horizontal, 24)
        .padding(.top, mode == .signUp ? 12 : 16)
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Password")
            HStack {
                Group {
                    if showPassword {
                        TextField("••••••••", text: $password)
                    } else {
                        SecureField("••••••••", text: $password)
                    }
                }
                .font(.sketch(15))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.textPrimary.opacity(0.45))
                        .font(.system(size: 16))
                }
            }
            .sketchTextField()
            .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.sketch(13, weight: .bold))
            .foregroundColor(.textPrimary.opacity(0.65))
    }

    // MARK: - Forgot Password
    private var forgotButton: some View {
        HStack {
            Spacer()
            Button { showForgot = true } label: {
                Text("Forgot password?")
                    .font(.sketch(13))
                    .foregroundColor(.userBlue)
                    .underline()
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Primary CTA
    private var primaryActionButton: some View {
        Button {
            if mode == .signIn {
                auth.signIn(email: email, password: password)
            } else {
                auth.signUp(email: email, password: password, name: name)
            }
        } label: {
            HStack(spacing: 8) {
                if auth.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.textPrimary)
                        .scaleEffect(0.85)
                }
                Text(mode == .signIn ? "Sign In →" : "Create Account →")
                    .font(.sketchBold(16))
                    .foregroundColor(.textPrimary)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(SketchButtonStyle(fillColor: .accentYellow))
        .disabled(auth.isLoading)
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // MARK: - Divider
    private var divider: some View {
        HStack(spacing: 12) {
            sketchLine
            Text("or")
                .font(.sketch(13))
                .foregroundColor(.textPrimary.opacity(0.4))
            sketchLine
        }
        .padding(.horizontal, 24)
    }

    private var sketchLine: some View {
        ZStack(alignment: .center) {
            // Slightly wobbly sketch line feel — two offset paths
            Rectangle()
                .fill(Color.sketchBorder.opacity(0.18))
                .frame(height: 1.5)
            Rectangle()
                .fill(Color.sketchBorder.opacity(0.08))
                .frame(height: 1)
                .offset(y: 1)
        }
    }

    // MARK: - Google Button
    private var googleButton: some View {
        Button { auth.signInWithGoogle() } label: {
            HStack(spacing: 10) {
                // Google "G" icon drawn with system colors
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(Color.sketchBorder.opacity(0.3), lineWidth: 1))
                    Text("G")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .red, .yellow, .green],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                Text("Continue with Google")
                    .font(.sketch(15, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(SketchButtonStyle(fillColor: Color.cardBackground))
        .disabled(auth.isLoading)
        .padding(.horizontal, 24)
    }

    // MARK: - Switch Mode Footer
    private var switchModeFooter: some View {
        HStack(spacing: 4) {
            Text(mode == .signIn ? "New here?" : "Already have an account?")
                .font(.sketch(13))
                .foregroundColor(.textPrimary.opacity(0.5))
            Button {
                withAnimation { mode = mode == .signIn ? .signUp : .signIn }
                auth.errorMessage = nil
            } label: {
                Text(mode == .signIn ? "Create account" : "Sign in")
                    .font(.sketch(13, weight: .bold))
                    .foregroundColor(.userBlue)
                    .underline()
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Error Banner
    private func errorBanner(_ message: String) -> some View {
        let isSuccess = message.hasPrefix("✓")
        return HStack(spacing: 10) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isSuccess ? .bothGreen : .hardRed)
                .font(.system(size: 16))
            Text(message)
                .font(.sketch(13))
                .foregroundColor(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(12)
        .background(isSuccess ? Color.bothGreen.opacity(0.15) : Color.hardRed.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSuccess ? Color.bothGreen : Color.hardRed, lineWidth: 1.5)
        )
    }

    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.textPrimary)
                    .scaleEffect(1.3)
                Text("Signing you in…")
                    .font(.sketch(14))
                    .foregroundColor(.textPrimary)
            }
            .padding(28)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.sketchBorder, lineWidth: 2)
            )
        }
    }

    // MARK: - Shake helper
    private func triggerShake() {
        withAnimation(.default) { shake = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { shake = false }
        }
    }
}

// MARK: - Shake Effect
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let amplitude: CGFloat = 6
        let shakeCount: CGFloat = 3
        let x = amplitude * sin(animatableData * .pi * shakeCount)
        return ProjectionTransform(CGAffineTransform(translationX: x, y: 0))
    }
}

// MARK: - Forgot Password Sheet
struct ForgotPasswordSheet: View {
    @Binding var email: String
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var localEmail: String = ""
    @State private var sent = false

    var body: some View {
        ZStack {
            DottedBackground()
            VStack(spacing: 24) {
                // Handle
                Capsule()
                    .fill(Color.sketchBorder.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 16)

                Text("Reset Password")
                    .font(.sketchBold(22))
                    .foregroundColor(.textPrimary)

                Text("Enter your email and we'll send a reset link.")
                    .font(.sketch(14))
                    .foregroundColor(.textPrimary.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.sketch(13, weight: .bold))
                        .foregroundColor(.textPrimary.opacity(0.65))
                    TextField("you@example.com", text: $localEmail)
                        .font(.sketch(15))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .sketchTextField()
                }
                .padding(.horizontal, 24)

                Button {
                    auth.resetPassword(email: localEmail)
                    sent = true
                } label: {
                    Text(sent ? "Link Sent ✓" : "Send Reset Link")
                        .font(.sketchBold(15))
                        .foregroundColor(.textPrimary)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SketchButtonStyle(fillColor: sent ? Color.bothGreen : Color.accentYellow))
                .padding(.horizontal, 24)
                .disabled(sent)

                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.sketch(14))
                        .foregroundColor(.textPrimary.opacity(0.5))
                        .underline()
                }

                Spacer()
            }
        }
        .onAppear { localEmail = email }
    }
}

#Preview {
    LoginView()
}

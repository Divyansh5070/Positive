
import SwiftUI

// MARK: - Buddy View
// Shows your buddy code + lets you connect/disconnect with a partner
struct BuddyView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var buddyCode: String    = ""
    @State private var isConnecting: Bool   = false
    @State private var isDisconnecting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var codeCopied: Bool     = false
    @State private var showDisconnectAlert  = false

    var myCode: String { store.myProfile?.buddyCode ?? "------" }
    var myName: String { store.myProfile?.displayName ?? "You" }
    var buddyName: String { store.buddyProfile?.displayName ?? "Buddy" }

    var body: some View {
        ZStack {
            DottedBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Handle bar
                    Capsule()
                        .fill(Color.sketchBorder.opacity(0.2))
                        .frame(width: 40, height: 4)
                        .padding(.top, 16)

                    // Title
                    HStack {
                        Text("Buddy Connect")
                            .font(.caveatBold(28))
                            .foregroundColor(.textPrimary)
                        Text("🤝").font(.system(size: 24))
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.textPrimary.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .background(Color.cardBackground)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.sketchBorder, lineWidth: 1.5))
                        }
                    }
                    .padding(.horizontal, 24)

                    // ── YOUR CODE CARD ────────────────────────────────────
                    VStack(spacing: 12) {
                        Text("Your Buddy Code")
                            .font(.caveat(16, weight: .bold))
                            .foregroundColor(.textPrimary.opacity(0.6))

                        Text(myCode)
                            .font(.sketchBold(38))
                            .foregroundColor(.textPrimary)
                            .tracking(8)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(Color.accentYellow.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.sketchBorder, lineWidth: 2)
                            )

                        Button {
                            UIPasteboard.general.string = myCode
                            withAnimation { codeCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { codeCopied = false }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 13))
                                Text(codeCopied ? "Copied!" : "Copy Code")
                                    .font(.caveat(15, weight: .bold))
                            }
                            .foregroundColor(.textPrimary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(SketchButtonStyle(fillColor: codeCopied ? Color.bothGreen : Color.cardBackground))

                        Text("Share this code with your buddy.")
                            .font(.caveat(13))
                            .foregroundColor(.textPrimary.opacity(0.45))
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .sketchCard(padding: 0)
                    .padding(.horizontal, 24)

                    // ── CONNECTED STATE ───────────────────────────────────
                    if store.isConnected {
                        VStack(spacing: 16) {
                            // Connected badge
                            HStack(spacing: 10) {
                                Circle().fill(Color.bothGreen).frame(width: 10, height: 10)
                                Text("Connected with \(buddyName)")
                                    .font(.caveat(17, weight: .bold))
                                    .foregroundColor(.textPrimary)
                            }

                            // Buddy stats
                            HStack(spacing: 20) {
                                statPill(label: "Problems", value: "\(store.buddyEntries.count)")
                                statPill(label: "Today",
                                         value: "\(store.buddyEntries.filter { $0.dateKey == store.todayKey }.count)")
                            }

                            // Disconnect
                            Button { showDisconnectAlert = true } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.badge.minus")
                                    Text("Disconnect")
                                        .font(.caveat(16, weight: .bold))
                                }
                                .foregroundColor(.hardRed)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SketchButtonStyle(fillColor: Color.hardRed.opacity(0.1)))
                        }
                        .padding(20)
                        .sketchCard(padding: 0)
                        .padding(.horizontal, 24)

                    } else {
                        // ── CONNECT FORM ─────────────────────────────────
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Enter Buddy's Code")
                                .font(.caveat(18, weight: .bold))
                                .foregroundColor(.textPrimary)

                            TextField("e.g. AB12CD", text: $buddyCode)
                                .font(.sketchBold(22))
                                .multilineTextAlignment(.center)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .tracking(6)
                                .sketchTextField()
                                .onChange(of: buddyCode) { _, v in
                                    buddyCode = String(v.uppercased().prefix(6))
                                }

                            Button {
                                connectToBuddy()
                            } label: {
                                HStack(spacing: 8) {
                                    if isConnecting {
                                        ProgressView()
                                            .tint(Color.textPrimary)
                                            .scaleEffect(0.85)
                                    }
                                    Text(isConnecting ? "Connecting…" : "Connect →")
                                        .font(.caveatBold(18))
                                        .foregroundColor(.textPrimary)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(SketchButtonStyle(fillColor: buddyCode.count == 6 ? .accentYellow : Color.tagBackground))
                            .disabled(buddyCode.count < 6 || isConnecting)

                            // Error / success messages
                            if let err = errorMessage {
                                feedbackBanner(err, isError: true)
                            }
                            if let success = successMessage {
                                feedbackBanner(success, isError: false)
                            }
                        }
                        .padding(20)
                        .sketchCard(padding: 0)
                        .padding(.horizontal, 24)
                    }

                    // How it works
                    howItWorksCard

                    Spacer(minLength: 40)
                }
            }
        }
        .alert("Disconnect Buddy?", isPresented: $showDisconnectAlert) {
            Button("Disconnect", role: .destructive) { disconnectBuddy() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You and \(buddyName) will no longer see each other's entries.")
        }
    }

    // MARK: - How it works card
    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How it works")
                .font(.caveat(18, weight: .bold))
                .foregroundColor(.textPrimary)

            step("1", "Share your buddy code with a friend")
            step("2", "They enter your code (or vice versa)")
            step("3", "Once connected, you'll both see each other's problem notes, approaches, and stats")
        }
        .padding(16)
        .sketchCard(padding: 0)
        .padding(.horizontal, 24)
    }

    private func step(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(num)
                .font(.caveatBold(16))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.textPrimary)
                .clipShape(Circle())
            Text(text)
                .font(.caveat(15))
                .foregroundColor(.textPrimary.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.caveatBold(26))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.caveat(13))
                .foregroundColor(.textPrimary.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.tagBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.sketchBorder, lineWidth: 1.5))
    }

    private func feedbackBanner(_ text: String, isError: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .hardRed : .bothGreen)
            Text(text)
                .font(.caveat(14))
                .foregroundColor(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(12)
        .background((isError ? Color.hardRed : Color.bothGreen).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(isError ? Color.hardRed : Color.bothGreen, lineWidth: 1.5))
    }

    // MARK: - Actions
    private func connectToBuddy() {
        errorMessage   = nil
        successMessage = nil
        isConnecting   = true
        Task {
            do {
                try await store.connectToBuddy(code: buddyCode)
                await MainActor.run {
                    successMessage = "Connected! 🎉 You can now see each other's progress."
                    buddyCode = ""
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            await MainActor.run { isConnecting = false }
        }
    }

    private func disconnectBuddy() {
        isDisconnecting = true
        Task {
            try? await store.disconnectBuddy()
            await MainActor.run { isDisconnecting = false }
        }
    }
}

#Preview {
    BuddyView().environmentObject(DataStore.shared)
}

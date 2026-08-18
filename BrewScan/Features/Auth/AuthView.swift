import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppState

    @State private var email = ""
    @State private var code = ""
    @State private var isCodeSent = false
    @State private var isLoading = false
    @State private var message = ""
    @State private var errorMessage = ""
    @State private var devCode: String?
    @State private var devMagicLink: String?

    var body: some View {
        ZStack {
            Color(hex: "#1A0F0A")
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header

                    VStack(spacing: 14) {
                        emailField

                        if isCodeSent {
                            codeField
                        }
                    }

                    if !message.isEmpty {
                        statusText(message, color: Color(hex: "#B0A090"))
                    }

                    if !errorMessage.isEmpty {
                        statusText(errorMessage, color: Color(hex: "#C8860A"))
                    }

                    if let devCode {
                        devLoginBox(code: devCode, magicLink: devMagicLink)
                    }

                    Button(action: primaryAction) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(Color(hex: "#1A0F0A"))
                            }
                            Text(isCodeSent ? "Verify Code" : "Email Me a Code")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#C8860A"))
                        .foregroundColor(Color(hex: "#1A0F0A"))
                        .cornerRadius(24)
                    }
                    .disabled(isLoading)

                    if isCodeSent {
                        Button("Send a new code") {
                            isCodeSent = false
                            code = ""
                            devCode = nil
                            devMagicLink = nil
                            requestLogin()
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color(hex: "#C8860A"))
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 80)
                .padding(.bottom, 44)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            email = appState.userProfile?.email ?? appState.authSession?.user.email ?? ""
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sign in")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)

            Text("Use your email to keep BrewScan ready across updates.")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#B0A090"))
                .lineSpacing(3)
        }
    }

    private var emailField: some View {
        TextField("", text: $email)
            .placeholder(when: email.isEmpty) {
                Text("Email address")
                    .foregroundColor(Color(hex: "#B0A090").opacity(0.7))
            }
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(16)
            .background(Color(hex: "#2D1F15"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#3D2A1A"), lineWidth: 1)
            )
            .disabled(isCodeSent)
    }

    private var codeField: some View {
        TextField("", text: $code)
            .placeholder(when: code.isEmpty) {
                Text("6-digit code")
                    .foregroundColor(Color(hex: "#B0A090").opacity(0.7))
            }
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .font(.system(size: 22, weight: .semibold, design: .monospaced))
            .foregroundColor(.white)
            .padding(16)
            .background(Color(hex: "#2D1F15"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#3D2A1A"), lineWidth: 1)
            )
            .onChange(of: code) { newValue in
                code = String(newValue.filter(\.isNumber).prefix(6))
            }
    }

    private func statusText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(color)
            .lineSpacing(3)
    }

    private func devLoginBox(code: String, magicLink: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TEST LOGIN")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#C8860A"))
                .tracking(1.2)

            Text("Code: \(code)")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)

            if let magicLink {
                Text(magicLink)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#B0A090"))
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(hex: "#2D1F15"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#C8860A").opacity(0.35), lineWidth: 1)
        )
    }

    private func primaryAction() {
        isCodeSent ? verifyCode() : requestLogin()
    }

    private func requestLogin() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@") else {
            errorMessage = "Enter a valid email address."
            return
        }

        isLoading = true
        errorMessage = ""
        message = ""

        Task {
            do {
                let response = try await AuthService.shared.requestLogin(
                    email: trimmedEmail,
                    name: appState.userProfile?.name
                )
                await MainActor.run {
                    isCodeSent = true
                    message = response.emailSent
                        ? "We sent a login code and magic link to \(response.email)."
                        : "Test mode is active. Use the code below."
                    devCode = response.devCode
                    devMagicLink = response.devMagicLink
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func verifyCode() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = String(code.filter(\.isNumber))
        guard trimmedCode.count == 6 else {
            errorMessage = "Enter the 6-digit code."
            return
        }

        isLoading = true
        errorMessage = ""

        Task {
            do {
                let session = try await AuthService.shared.verifyCode(email: trimmedEmail, code: trimmedCode)
                await MainActor.run {
                    appState.signIn(session)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

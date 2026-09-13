import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppState

    @State private var email = ""
    @State private var code = ""
    @State private var isCodeSent = false
    @State private var isLoading = false
    @State private var message = ""
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color(hex: "#FFFFFF")
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
                        statusText(message, color: Color(hex: "#717171"))
                    }

                    if !errorMessage.isEmpty {
                        statusText(errorMessage, color: Color(hex: "#B97812"))
                    }

                    Button(action: primaryAction) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(Color(hex: "#FFFFFF"))
                            }
                            Text(isCodeSent ? "Verify Code" : "Email Me a Code")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#B97812"))
                        .foregroundColor(Color(hex: "#FFFFFF"))
                        .cornerRadius(24)
                    }
                    .disabled(isLoading)

                    if isCodeSent {
                        Button("Send a new code") {
                            isCodeSent = false
                            code = ""
                            requestLogin()
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color(hex: "#B97812"))
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 80)
                .padding(.bottom, 44)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            email = appState.userProfile?.email ?? appState.authSession?.user.email ?? ""
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sign in to save")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color(hex: "#222222"))

            Text("Enter your email and we'll send you a one-time code. No password needed.")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#717171"))
                .lineSpacing(3)
        }
    }

    private var emailField: some View {
        TextField("", text: $email)
            .placeholder(when: email.isEmpty) {
                Text("Email address")
                    .foregroundColor(Color(hex: "#717171").opacity(0.7))
            }
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "#222222"))
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#E8E2DC"), lineWidth: 1)
            )
            .disabled(isCodeSent)
    }

    private var codeField: some View {
        TextField("", text: $code)
            .placeholder(when: code.isEmpty) {
                Text("6-digit code")
                    .foregroundColor(Color(hex: "#717171").opacity(0.7))
            }
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .font(.system(size: 22, weight: .semibold, design: .monospaced))
            .foregroundColor(Color(hex: "#222222"))
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#E8E2DC"), lineWidth: 1)
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
                try await AuthService.shared.requestOTP(email: trimmedEmail)
                await MainActor.run {
                    isCodeSent = true
                    message = "We sent a 6-digit code to \(trimmedEmail)."
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
                let session = try await AuthService.shared.verifyOTP(email: trimmedEmail, token: trimmedCode)
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

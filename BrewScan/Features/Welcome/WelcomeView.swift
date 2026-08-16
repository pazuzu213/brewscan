import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPage = 0
    @State private var didAppear = false
    @State private var name = ""
    @State private var email = ""
    @State private var machineType: MachineType = .original
    @State private var preferredStrength: BrewStrength = .medium
    @State private var showValidation = false

    var body: some View {
        TabView(selection: $selectedPage) {
            splashPage
                .tag(0)

            setupPage
                .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(Color(hex: "#1A0F0A").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                didAppear = true
            }
        }
    }

    private var splashPage: some View {
        ZStack {
            Color(hex: "#1A0F0A")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 18) {
                    Text("☕")
                        .font(.system(size: 96))
                        .scaleEffect(didAppear ? 1 : 0.86)
                        .opacity(didAppear ? 1 : 0)

                    Text("BrewScan")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(didAppear ? 1 : 0)

                    Text("Discover every pod. Perfect every brew.")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "#C8860A"))
                        .multilineTextAlignment(.center)
                        .opacity(didAppear ? 1 : 0)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedPage = 1
                    }
                } label: {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#C8860A"))
                        .foregroundColor(Color(hex: "#1A0F0A"))
                        .cornerRadius(24)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    private var setupPage: some View {
        ZStack {
            Color(hex: "#1A0F0A")
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Let's get you set up")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text("Tell BrewScan how you like to brew.")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#B0A090"))
                    }
                    .padding(.top, 56)

                    VStack(spacing: 14) {
                        welcomeTextField(title: "Your name", text: $name)

                        welcomeTextField(title: "Email address", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        setupLabel("Machine type")

                        HStack(spacing: 10) {
                            ForEach(MachineType.allCases, id: \.self) { type in
                                pickerCard(
                                    title: type.rawValue,
                                    isSelected: machineType == type
                                ) {
                                    machineType = type
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        setupLabel("Preferred strength")

                        FlowLayout(spacing: 8) {
                            ForEach(BrewStrength.allCases, id: \.self) { strength in
                                strengthPill(
                                    strength: strength,
                                    isSelected: preferredStrength == strength
                                ) {
                                    preferredStrength = strength
                                }
                            }
                        }
                    }

                    if showValidation {
                        Text("Name and email are required.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#C8860A"))
                    }

                    Button(action: completeOnboarding) {
                        Text("Start Brewing →")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#C8860A"))
                            .foregroundColor(Color(hex: "#1A0F0A"))
                            .cornerRadius(24)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func welcomeTextField(title: String, text: Binding<String>) -> some View {
        TextField("", text: text)
            .placeholder(when: text.wrappedValue.isEmpty) {
                Text(title)
                    .foregroundColor(Color(hex: "#B0A090").opacity(0.7))
            }
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(16)
            .background(Color(hex: "#2D1F15"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#3D2A1A"), lineWidth: 1)
            )
    }

    private func setupLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: "#B0A090"))
            .tracking(1.5)
    }

    private func pickerCard(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? Color(hex: "#C8860A") : Color(hex: "#2D1F15"))
                .foregroundColor(isSelected ? Color(hex: "#1A0F0A") : Color(hex: "#B0A090"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : Color(hex: "#3D2A1A"), lineWidth: 1)
                )
        }
    }

    private func strengthPill(strength: BrewStrength, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(strength.rawValue)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "#C8860A") : Color(hex: "#2D1F15"))
                .foregroundColor(isSelected ? Color(hex: "#1A0F0A") : Color(hex: "#B0A090"))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isSelected ? Color.clear : Color(hex: "#3D2A1A"), lineWidth: 1)
                )
        }
    }

    private func completeOnboarding() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty else {
            showValidation = true
            return
        }

        let profile = UserProfile(
            name: trimmedName,
            email: trimmedEmail,
            machineType: machineType,
            milkPreference: false,
            preferredStrength: preferredStrength,
            createdAt: Date()
        )

        appState.saveProfile(profile)
        appState.hasCompletedOnboarding = true
    }
}

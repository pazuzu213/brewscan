import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var machineType: MachineType = .nespresso
    @State private var preferredStrength: BrewStrength = .medium

    var body: some View {
        setupPage
        .background(Color.white.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    private var setupPage: some View {
        ZStack {
            Color(hex: "#FFFFFF")
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What do you brew with?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(hex: "#222222"))

                        Text("Pick your pod system so PodSnap AI can tune the scanner and catalog.")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#717171"))
                    }
                    .padding(.top, 56)

                    VStack(alignment: .leading, spacing: 12) {
                        setupLabel("Pod system")

                        VStack(spacing: 10) {
                            ForEach(MachineType.onboardingCases, id: \.self) { type in
                                systemCard(type: type)
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

                    Button(action: completeOnboarding) {
                        Text("Start Scanning")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#B97812"))
                            .foregroundColor(Color(hex: "#FFFFFF"))
                            .cornerRadius(24)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func setupLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: "#717171"))
            .tracking(1.5)
    }

    private func pickerCard(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? Color(hex: "#B97812") : Color.white)
                .foregroundColor(isSelected ? Color.white : Color(hex: "#222222"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : Color(hex: "#F7F7F7"), lineWidth: 1)
                )
        }
    }

    private func systemCard(type: MachineType) -> some View {
        Button {
            machineType = type
        } label: {
            HStack(spacing: 14) {
                Image(systemName: iconName(for: type))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(machineType == type ? Color.white : Color(hex: "#B97812"))
                    .frame(width: 34, height: 34)
                    .background(machineType == type ? Color.white.opacity(0.28) : Color(hex: "#F7F7F7"))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(type.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(machineType == type ? Color.white : Color(hex: "#222222"))

                    Text(subtitle(for: type))
                        .font(.system(size: 13))
                        .foregroundColor(machineType == type ? Color.white.opacity(0.78) : Color(hex: "#717171"))
                }

                Spacer()

                if machineType == type {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color.white)
                }
            }
            .padding(16)
            .background(machineType == type ? Color(hex: "#B97812") : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(machineType == type ? Color.clear : Color(hex: "#F7F7F7"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func strengthPill(strength: BrewStrength, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(strength.rawValue)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "#B97812") : Color(hex: "#F7F7F7"))
                .foregroundColor(isSelected ? Color.white : Color(hex: "#222222"))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isSelected ? Color.clear : Color(hex: "#F7F7F7"), lineWidth: 1)
                )
        }
    }

    private func completeOnboarding() {
        let profile = UserProfile(
            name: "",
            email: "",
            machineType: machineType,
            milkPreference: false,
            preferredStrength: preferredStrength,
            createdAt: Date()
        )

        appState.saveProfile(profile)
        appState.hasCompletedOnboarding = true
    }

    private func iconName(for type: MachineType) -> String {
        switch type {
        case .nespresso, .original, .vertuo:
            return "cup.and.saucer.fill"
        case .keurig:
            return "mug.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }

    private func subtitle(for type: MachineType) -> String {
        switch type {
        case .nespresso, .original, .vertuo:
            return "Original and Vertuo capsules"
        case .keurig:
            return "K-Cup pods from major brands"
        case .other:
            return "Browse and scan whatever you have"
        }
    }
}

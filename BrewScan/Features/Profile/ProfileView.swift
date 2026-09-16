import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEditProfile = false
    @State private var selectedScan: SavedScan? = nil
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false

    private let db = PodDatabase.shared

    private var sortedScans: [SavedScan] {
        appState.savedScans.sorted { $0.date > $1.date }
    }

    private var savedRecipes: [Recipe] {
        appState.savedRecipeIds.compactMap { db.recipe(byId: $0) }.sorted { $0.name < $1.name }
    }

    private var favoritePods: [Pod] {
        appState.favoritePodIds.compactMap { db.pod(byId: $0) }.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#FFFFFF")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        scanHistorySection
                        favoritePodsSection
                        savedRecipesSection
                        profileCard
                        preferencesSection
                        accountSection
                    }
                    .padding(20)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#FFFFFF"), for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
                    .environmentObject(appState)
            }
            .sheet(item: $selectedScan) { scan in
                SavedScanDetailView(scan: scan)
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                SafariView(url: URL(string: "https://pazuzu213.github.io/brewscan/privacy.html")!)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showTerms) {
                SafariView(url: URL(string: "https://pazuzu213.github.io/brewscan/terms.html")!)
                    .ignoresSafeArea()
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.light)
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(appState.userProfile?.name ?? "PodSnap AI User")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "#222222"))

                    Text(appState.userProfile?.email ?? "No email added")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#717171"))
                }

                Spacer()

                Button("Edit") {
                    showEditProfile = true
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#B97812"))
            }

            HStack(spacing: 10) {
                badge(appState.userProfile?.machineType.displayName ?? "Nespresso")
                badge(appState.userProfile?.preferredStrength.rawValue ?? "Medium")
            }
        }
        .padding(18)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#E8E2DC"), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
    }

    private var savedRecipesSection: some View {
        section(title: "Saved Recipes") {
            if savedRecipes.isEmpty {
                emptyState("No saved recipes yet.")
            } else {
                VStack(spacing: 0) {
                    ForEach(savedRecipes) { recipe in
                        row(icon: recipe.emoji, title: recipe.name, subtitle: recipe.prepTime)
                    }
                }
                .background(Color(hex: "#FFFFFF"))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#E8E2DC"), lineWidth: 1))
            }
        }
    }

    private var favoritePodsSection: some View {
        section(title: "Favourite Pods") {
            if favoritePods.isEmpty {
                emptyState("No favourite pods yet.")
            } else {
                VStack(spacing: 0) {
                    ForEach(favoritePods) { pod in
                        podRow(pod)
                    }
                }
                .background(Color(hex: "#FFFFFF"))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#E8E2DC"), lineWidth: 1))
            }
        }
    }

    private var scanHistorySection: some View {
        section(title: "My Coffee Library") {
            if sortedScans.isEmpty {
                emptyState("Scanned pods will appear here automatically.")
            } else {
                List {
                    ForEach(sortedScans) { scan in
                        Button {
                            selectedScan = scan
                        } label: {
                            scanRow(scan)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color(hex: "#FFFFFF"))
                        .listRowSeparatorTint(Color(hex: "#E8E2DC"))
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                appState.deleteScans(ids: [scan.id])
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(height: CGFloat(min(max(sortedScans.count, 1), 6)) * 76)
                .background(Color(hex: "#FFFFFF"))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#E8E2DC"), lineWidth: 1))
            }
        }
    }

    private var preferencesSection: some View {
        section(title: "Preferences") {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Machine type")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#717171"))

                    HStack(spacing: 10) {
                        ForEach(MachineType.onboardingCases, id: \.self) { type in
                            preferenceButton(
                                title: type.displayName,
                                isSelected: appState.userProfile?.machineType == type
                            ) {
                                updateProfile { $0.machineType = type }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Preferred strength")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#717171"))

                    FlowLayout(spacing: 8) {
                        ForEach(BrewStrength.allCases, id: \.self) { strength in
                            preferencePill(
                                title: strength.rawValue,
                                isSelected: appState.userProfile?.preferredStrength == strength
                            ) {
                                updateProfile { $0.preferredStrength = strength }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(hex: "#FFFFFF"))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#E8E2DC"), lineWidth: 1))
        }
    }

    private var accountSection: some View {
        section(title: "Account") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(appState.authSession?.user.email ?? appState.userProfile?.email ?? "No email added")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#222222"))

                    Text(appState.isAuthenticated ? "Signed in with email" : "Not signed in")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#717171"))
                }

                if appState.isAuthenticated {
                    Button("Sign Out") {
                        appState.signOut()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#B97812"))
                } else {
                    Button("Sign In") {
                        appState.isShowingAuth = true
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#B97812"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(hex: "#FFFFFF"))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#E8E2DC"), lineWidth: 1))

            // Legal
            VStack(spacing: 0) {
                legalRow("Privacy Policy") { showPrivacyPolicy = true }
                Divider().padding(.horizontal, 14)
                legalRow("Terms & Conditions") { showTerms = true }
            }
            .background(Color(hex: "#FFFFFF"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#E8E2DC"), lineWidth: 1)
            )
        }
    }

    private func legalRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#222222"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#717171").opacity(0.5))
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#717171"))
                .tracking(1.5)

            content()
        }
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(hex: "#E8E2DC"))
            .foregroundColor(Color(hex: "#B97812"))
            .cornerRadius(24)
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "#717171"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(hex: "#FFFFFF"))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#E8E2DC"), lineWidth: 1))
    }

    private func row(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 22))
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#222222"))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#717171"))
            }

            Spacer()
        }
        .padding(14)
    }

    private func podRow(_ pod: Pod) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: pod.color))
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(pod.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#222222"))
                Text("\(pod.displayLine) • Intensity \(pod.intensity)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#717171"))
            }

            Spacer()
        }
        .padding(14)
    }

    private func scanRow(_ scan: SavedScan) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: scan.podColor))
                .frame(width: 34, height: 34)
                .overlay {
                    if let data = scan.imageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                    }
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(scan.podName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#222222"))

                HStack(spacing: 5) {
                    Text(scan.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#717171"))

                    if !scan.notes.isEmpty {
                        Text("·")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#717171"))
                        Text("\(scan.notes.count) note\(scan.notes.count == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#B97812"))
                    }

                    if let rating = scan.rating {
                        Text("·")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#717171"))
                        Text(String(repeating: "★", count: rating))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#B97812"))
                    }
                }
            }

            Spacer()

            Text("\(Int(scan.confidence * 100))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#B97812"))

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "#717171").opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func preferenceButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color(hex: "#B97812") : Color(hex: "#E8E2DC"))
                .foregroundColor(isSelected ? Color(hex: "#FFFFFF") : Color(hex: "#717171"))
                .cornerRadius(16)
        }
    }

    private func preferencePill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(isSelected ? Color(hex: "#B97812") : Color(hex: "#E8E2DC"))
                .foregroundColor(isSelected ? Color(hex: "#FFFFFF") : Color(hex: "#717171"))
                .cornerRadius(24)
        }
    }

    private func updateProfile(_ mutate: (inout UserProfile) -> Void) {
        var profile = appState.userProfile ?? UserProfile(
            name: "PodSnap AI User",
            email: "",
            machineType: .nespresso,
            milkPreference: false,
            preferredStrength: .medium,
            createdAt: Date()
        )
        mutate(&profile)
        appState.saveProfile(profile)
    }

    private func deleteScans(at offsets: IndexSet) {
        let ids = Set(offsets.map { sortedScans[$0].id })
        appState.deleteScans(ids: ids)
    }
}

private struct EditProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#FFFFFF")
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    profileTextField("Name", text: $name)
                    profileTextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#717171"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#B97812"))
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.light)
        .onAppear {
            name = appState.userProfile?.name ?? ""
            email = appState.userProfile?.email ?? ""
        }
    }

    private func profileTextField(_ title: String, text: Binding<String>) -> some View {
        TextField("", text: text)
            .placeholder(when: text.wrappedValue.isEmpty) {
                Text(title)
                    .foregroundColor(Color(hex: "#717171").opacity(0.7))
            }
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "#222222"))
            .padding(16)
            .background(Color(hex: "#FFFFFF"))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#E8E2DC"), lineWidth: 1))
    }

    private func save() {
        var profile = appState.userProfile ?? UserProfile(
            name: "",
            email: "",
            machineType: .nespresso,
            milkPreference: false,
            preferredStrength: .medium,
            createdAt: Date()
        )
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        appState.saveProfile(profile)
    }
}

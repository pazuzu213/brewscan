import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEditProfile = false

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
                Color(hex: "#1A0F0A")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        profileCard
                        savedRecipesSection
                        favoritePodsSection
                        scanHistorySection
                        preferencesSection
                        accountSection
                    }
                    .padding(20)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#1A0F0A"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
                    .environmentObject(appState)
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(appState.userProfile?.name ?? "BrewScan User")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text(appState.userProfile?.email ?? "No email added")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#B0A090"))
                }

                Spacer()

                Button("Edit") {
                    showEditProfile = true
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#C8860A"))
            }

            HStack(spacing: 10) {
                badge(appState.userProfile?.machineType.rawValue ?? "Original")
                badge(appState.userProfile?.preferredStrength.rawValue ?? "Medium")
            }
        }
        .padding(18)
        .background(Color(hex: "#2D1F15"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#3D2A1A"), lineWidth: 1)
        )
    }

    private var savedRecipesSection: some View {
        section(title: "My Saved Recipes") {
            if savedRecipes.isEmpty {
                emptyState("No saved recipes yet.")
            } else {
                VStack(spacing: 0) {
                    ForEach(savedRecipes) { recipe in
                        row(icon: recipe.emoji, title: recipe.name, subtitle: recipe.prepTime)
                    }
                }
                .background(Color(hex: "#2D1F15"))
                .cornerRadius(16)
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
                .background(Color(hex: "#2D1F15"))
                .cornerRadius(16)
            }
        }
    }

    private var scanHistorySection: some View {
        section(title: "Scan History") {
            if sortedScans.isEmpty {
                emptyState("Scans you save will show up here.")
            } else {
                List {
                    ForEach(sortedScans) { scan in
                        scanRow(scan)
                            .listRowBackground(Color(hex: "#2D1F15"))
                    }
                    .onDelete(perform: deleteScans)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(height: CGFloat(min(max(sortedScans.count, 1), 6)) * 68)
                .cornerRadius(16)
            }
        }
    }

    private var preferencesSection: some View {
        section(title: "Preferences") {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Machine type")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#B0A090"))

                    HStack(spacing: 10) {
                        ForEach(MachineType.allCases, id: \.self) { type in
                            preferenceButton(
                                title: type.rawValue,
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
                        .foregroundColor(Color(hex: "#B0A090"))

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
            .background(Color(hex: "#2D1F15"))
            .cornerRadius(16)
        }
    }

    private var accountSection: some View {
        section(title: "Account") {
            VStack(alignment: .leading, spacing: 8) {
                Text(appState.userProfile?.email ?? "No email added")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text("Magic-link auth coming soon")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#B0A090"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(hex: "#2D1F15"))
            .cornerRadius(16)
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#B0A090"))
                .tracking(1.5)

            content()
        }
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(hex: "#3D2A1A"))
            .foregroundColor(Color(hex: "#C8860A"))
            .cornerRadius(24)
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "#B0A090"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(hex: "#2D1F15"))
            .cornerRadius(16)
    }

    private func row(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 22))
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#B0A090"))
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
                    .foregroundColor(.white)
                Text("\(pod.line) • Intensity \(pod.intensity)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#B0A090"))
            }

            Spacer()
        }
        .padding(14)
    }

    private func scanRow(_ scan: SavedScan) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: scan.podColor))
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(scan.podName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(scan.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#B0A090"))
            }

            Spacer()

            Text("\(Int(scan.confidence * 100))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#C8860A"))
        }
        .padding(.vertical, 4)
    }

    private func preferenceButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color(hex: "#C8860A") : Color(hex: "#3D2A1A"))
                .foregroundColor(isSelected ? Color(hex: "#1A0F0A") : Color(hex: "#B0A090"))
                .cornerRadius(16)
        }
    }

    private func preferencePill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(isSelected ? Color(hex: "#C8860A") : Color(hex: "#3D2A1A"))
                .foregroundColor(isSelected ? Color(hex: "#1A0F0A") : Color(hex: "#B0A090"))
                .cornerRadius(24)
        }
    }

    private func updateProfile(_ mutate: (inout UserProfile) -> Void) {
        var profile = appState.userProfile ?? UserProfile(
            name: "BrewScan User",
            email: "",
            machineType: .original,
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
                Color(hex: "#1A0F0A")
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
                        .foregroundColor(Color(hex: "#B0A090"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#C8860A"))
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .onAppear {
            name = appState.userProfile?.name ?? ""
            email = appState.userProfile?.email ?? ""
        }
    }

    private func profileTextField(_ title: String, text: Binding<String>) -> some View {
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
    }

    private func save() {
        var profile = appState.userProfile ?? UserProfile(
            name: "",
            email: "",
            machineType: .original,
            milkPreference: false,
            preferredStrength: .medium,
            createdAt: Date()
        )
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        appState.saveProfile(profile)
    }
}

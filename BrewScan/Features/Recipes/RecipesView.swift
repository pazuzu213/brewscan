import SwiftUI

struct RecipesView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedRecipe: Recipe?
    @State private var showSavedOnly = false
    private let db = PodDatabase.shared

    private var visibleRecipes: [Recipe] {
        let recipes = db.allRecipes()
        guard showSavedOnly else { return recipes }
        return recipes.filter { appState.savedRecipeIds.contains($0.id) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#1A0F0A")
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Header banner
                        recipeBanner

                        Picker("Recipes", selection: $showSavedOnly) {
                            Text("All").tag(false)
                            Text("Saved").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)

                        Group {
                            if visibleRecipes.isEmpty {
                                Text("Saved recipes will appear here.")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#B0A090"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(Color(hex: "#2D1F15"))
                                    .cornerRadius(16)
                                    .padding(.horizontal, 16)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(visibleRecipes) { recipe in
                                        RecipeRow(recipe: recipe)
                                            .onTapGesture {
                                                selectedRecipe = recipe
                                            }

                                        if recipe.id != visibleRecipes.last?.id {
                                            Divider()
                                                .background(Color(hex: "#2D1F15"))
                                                .padding(.leading, 72)
                                        }
                                    }
                                }
                                .background(Color(hex: "#2D1F15"))
                                .cornerRadius(16)
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Recipes")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#1A0F0A"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
        .navigationViewStyle(.stack)
    }

    private var recipeBanner: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#8B4513").opacity(0.4),
                            Color(hex: "#1A0F0A")
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 100)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(db.allRecipes().count) Recipes")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Crafted for Nespresso pods")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#B0A090"))
                }
                Spacer()
                Text("☕")
                    .font(.system(size: 52))
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Recipe Row

struct RecipeRow: View {
    @EnvironmentObject var appState: AppState
    let recipe: Recipe
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 16) {
            // Emoji circle
            ZStack {
                Circle()
                    .fill(Color(hex: "#1A0F0A"))
                    .frame(width: 48, height: 48)
                Text(recipe.emoji)
                    .font(.system(size: 24))
            }

            // Info
            VStack(alignment: .leading, spacing: 5) {
                Text(recipe.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    // Difficulty badge
                    Text(recipe.difficulty)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: recipe.difficultyColor).opacity(0.2))
                        .foregroundColor(Color(hex: recipe.difficultyColor))
                        .cornerRadius(6)

                    // Time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(recipe.prepTime)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "#B0A090"))

                    // Compatible pods count
                    HStack(spacing: 4) {
                        Image(systemName: "capsule")
                            .font(.system(size: 11))
                        Text("\(recipe.compatiblePodIds.count) pods")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "#B0A090"))
                }
            }

            Spacer()

            Button {
                appState.toggleSavedRecipe(recipe.id)
            } label: {
                Image(systemName: appState.isRecipeSaved(recipe.id) ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#C8860A"))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: "#1A0F0A"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#B0A090").opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            isPressed ? Color(hex: "#3D2A1A") : Color(hex: "#2D1F15")
        )
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 100, maximumDistance: 50) {
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

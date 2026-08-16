import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var checkedIngredients: Set<Int> = []
    @State private var completedSteps: Set<Int> = []

    private let db = PodDatabase.shared

    private var compatiblePods: [Pod] {
        db.pods(forRecipe: recipe)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#1A0F0A")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Hero header
                        recipeHeroHeader

                        // Content
                        VStack(alignment: .leading, spacing: 28) {
                            // Ingredients
                            ingredientsSection

                            // Steps
                            stepsSection

                            // Compatible pods
                            if !compatiblePods.isEmpty {
                                compatiblePodsSection
                            }
                        }
                        .padding(.top, 28)
                        .padding(.bottom, 48)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        appState.toggleSavedRecipe(recipe.id)
                    } label: {
                        Image(systemName: appState.isRecipeSaved(recipe.id) ? "bookmark.fill" : "bookmark")
                            .foregroundColor(Color(hex: "#C8860A"))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#C8860A"))
                }
            }
            .toolbarBackground(Color(hex: "#1A0F0A"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Hero Header

    private var recipeHeroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#8B4513").opacity(0.5),
                            Color(hex: "#2D1F15").opacity(0.8),
                            Color(hex: "#1A0F0A")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 240)

            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Big emoji
                Text(recipe.emoji)
                    .font(.system(size: 72))

                VStack(alignment: .leading, spacing: 10) {
                    Text(recipe.name)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 10) {
                        // Difficulty badge
                        HStack(spacing: 5) {
                            Image(systemName: difficultyIcon)
                                .font(.system(size: 12))
                            Text(recipe.difficulty)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: recipe.difficultyColor).opacity(0.2))
                        .foregroundColor(Color(hex: recipe.difficultyColor))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: recipe.difficultyColor).opacity(0.4), lineWidth: 1)
                        )

                        // Time badge
                        HStack(spacing: 5) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(recipe.prepTime)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#2D1F15"))
                        .foregroundColor(Color(hex: "#B0A090"))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Ingredients")

            VStack(spacing: 0) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack(spacing: 14) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if checkedIngredients.contains(index) {
                                    checkedIngredients.remove(index)
                                } else {
                                    checkedIngredients.insert(index)
                                }
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(
                                        checkedIngredients.contains(index) ?
                                        Color(hex: "#C8860A") : Color(hex: "#B0A090").opacity(0.4),
                                        lineWidth: 1.5
                                    )
                                    .frame(width: 24, height: 24)

                                if checkedIngredients.contains(index) {
                                    Circle()
                                        .fill(Color(hex: "#C8860A"))
                                        .frame(width: 16, height: 16)

                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }

                        Text(ingredient)
                            .font(.system(size: 15))
                            .foregroundColor(
                                checkedIngredients.contains(index) ?
                                Color(hex: "#B0A090") : .white
                            )
                            .strikethrough(checkedIngredients.contains(index), color: Color(hex: "#B0A090"))

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .animation(.easeInOut(duration: 0.15), value: checkedIngredients.contains(index))

                    if index < recipe.ingredients.count - 1 {
                        Divider()
                            .background(Color(hex: "#1A0F0A"))
                            .padding(.leading, 54)
                    }
                }
            }
            .background(Color(hex: "#2D1F15"))
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Steps Section

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Instructions")

            VStack(spacing: 12) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        // Step number
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if completedSteps.contains(index) {
                                    completedSteps.remove(index)
                                } else {
                                    completedSteps.insert(index)
                                }
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        completedSteps.contains(index) ?
                                        Color(hex: "#C8860A") : Color(hex: "#2D1F15")
                                    )
                                    .frame(width: 32, height: 32)

                                if completedSteps.contains(index) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color(hex: "#C8860A"))
                                }
                            }
                        }

                        Text(step)
                            .font(.system(size: 15))
                            .foregroundColor(
                                completedSteps.contains(index) ?
                                Color(hex: "#B0A090") : .white
                            )
                            .lineSpacing(4)
                            .padding(.top, 6)
                            .strikethrough(completedSteps.contains(index), color: Color(hex: "#B0A090"))

                        Spacer()
                    }
                    .padding(14)
                    .background(Color(hex: "#2D1F15"))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                completedSteps.contains(index) ?
                                Color(hex: "#C8860A").opacity(0.3) : Color(hex: "#3D2A1A"),
                                lineWidth: 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.15), value: completedSteps.contains(index))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Compatible Pods Section

    private var compatiblePodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Best With These Pods")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(compatiblePods) { pod in
                        compatiblePodChip(pod: pod)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func compatiblePodChip(pod: Pod) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: pod.color))
                .frame(width: 20, height: 20)
                .shadow(color: Color(hex: pod.color).opacity(0.5), radius: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(pod.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(pod.line)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#B0A090"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "#2D1F15"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#3D2A1A"), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: "#B0A090"))
            .tracking(1.5)
            .padding(.horizontal, 20)
    }

    private var difficultyIcon: String {
        switch recipe.difficulty {
        case "Easy": return "star"
        case "Medium": return "star.leadinghalf.filled"
        case "Hard": return "star.fill"
        default: return "star"
        }
    }
}

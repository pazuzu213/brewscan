import SwiftUI

struct PodDetailView: View {
    let pod: Pod
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    private let db = PodDatabase.shared

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#1A0F0A")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        detailHeader

                        // Content
                        VStack(alignment: .leading, spacing: 24) {
                            // Description
                            descriptionSection

                            // Tasting Notes
                            tastingNotesSection

                            // Intensity meter
                            intensitySection

                            // Flavor profile bars
                            flavorProfileSection

                            // Origin & Roast
                            originSection

                            // Recipes
                            let recipes = db.recipes(forPod: pod)
                            if !recipes.isEmpty {
                                recipesSection(recipes: recipes)
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        appState.toggleFavoritePod(pod.id)
                    } label: {
                        Image(systemName: appState.isPodFavorite(pod.id) ? "heart.fill" : "heart")
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

    // MARK: - Header

    private var detailHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: pod.color).opacity(0.7),
                            Color(hex: pod.color).opacity(0.3),
                            Color(hex: "#1A0F0A")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)

            // Decorative circles
            ZStack {
                Circle()
                    .fill(Color(hex: pod.color).opacity(0.15))
                    .frame(width: 200, height: 200)
                    .offset(x: 130, y: -50)

                Circle()
                    .fill(Color(hex: pod.color).opacity(0.1))
                    .frame(width: 140, height: 140)
                    .offset(x: 160, y: 30)
            }

            // Content
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pod.name)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)

                        HStack(spacing: 8) {
                            lineBadge
                            intensityBadge
                        }
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color(hex: pod.color).opacity(0.3))
                            .frame(width: 76, height: 76)
                            .blur(radius: 10)

                        Circle()
                            .fill(Color(hex: pod.color))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 2)
                            )
                            .shadow(
                                color: Color(hex: pod.color).opacity(0.5),
                                radius: 16,
                                x: 0,
                                y: 8
                            )

                        // Capsule shape
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 22, height: 32)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Content Sections

    private var descriptionSection: some View {
        Text(pod.description)
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "#B0A090"))
            .lineSpacing(5)
            .padding(.horizontal, 20)
    }

    private var tastingNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Tasting Notes")

            FlowLayout(spacing: 8) {
                ForEach(pod.tastingNotes, id: \.self) { note in
                    pillView(note)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("Intensity")
                Spacer()
                Text("\(pod.intensity) / 13")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#C8860A"))
                    .padding(.trailing, 20)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#2D1F15"))
                        .frame(height: 14)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#C8A96E"), Color(hex: "#3D1A08")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(pod.intensity) / 13.0,
                            height: 14
                        )
                }
            }
            .frame(height: 14)
            .padding(.horizontal, 20)

            Text(pod.intensityLabel)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#B0A090"))
                .padding(.horizontal, 20)
        }
    }

    private var flavorProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Flavor Profile")

            VStack(spacing: 10) {
                flavorBar(label: "Body", level: pod.bodyLevel)
                flavorBar(label: "Acidity", level: pod.acidityLevel)
                flavorBar(label: "Bitterness", level: pod.bitternessLevel)
            }
            .padding(16)
            .background(Color(hex: "#2D1F15"))
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }

    private var originSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Origin & Brew Details")

            VStack(spacing: 0) {
                infoRow(icon: "globe", label: "Origin", value: pod.origin)
                Divider().background(Color(hex: "#1A0F0A"))
                infoRow(icon: "flame.fill", label: "Roast Level", value: pod.roast)
                Divider().background(Color(hex: "#1A0F0A"))
                infoRow(icon: "cup.and.saucer.fill", label: "Recommended Cup", value: pod.recommendedCupSize)
                Divider().background(Color(hex: "#1A0F0A"))
                infoRow(icon: "thermometer.medium", label: "Brew Temperature", value: pod.brewTemp)
                Divider().background(Color(hex: "#1A0F0A"))
                infoRow(icon: "wind", label: "Aroma Profile", value: pod.aromaProfile)
            }
            .background(Color(hex: "#2D1F15"))
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func recipesSection(recipes: [Recipe]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Recipes for This Pod")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            catalogRecipeCard(recipe: recipe)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Helper Views

    private var lineBadge: some View {
        Text(pod.line)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(pod.lineColor.opacity(0.25))
            .foregroundColor(pod.lineColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(pod.lineColor.opacity(0.5), lineWidth: 1)
            )
    }

    private var intensityBadge: some View {
        Text("Intensity \(pod.intensity)")
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(hex: "#2D1F15"))
            .foregroundColor(Color(hex: "#C8860A"))
            .cornerRadius(8)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: "#B0A090"))
            .tracking(1.5)
            .padding(.horizontal, 20)
    }

    private func pillView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(hex: "#2D1F15"))
            .foregroundColor(Color(hex: "#C8860A"))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "#C8860A").opacity(0.3), lineWidth: 1)
            )
    }

    private func flavorBar(label: String, level: Int) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#B0A090"))
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#1A0F0A"))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#C8860A"))
                        .frame(
                            width: geo.size.width * CGFloat(level) / 5.0,
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            Text("\(level)/5")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#B0A090"))
                .frame(width: 30, alignment: .trailing)
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#C8860A"))
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#B0A090"))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 180, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func catalogRecipeCard(recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recipe.emoji)
                .font(.system(size: 32))

            Text(recipe.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)

            HStack(spacing: 6) {
                Text(recipe.difficulty)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: recipe.difficultyColor).opacity(0.2))
                    .foregroundColor(Color(hex: recipe.difficultyColor))
                    .cornerRadius(6)

                Text(recipe.prepTime)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#B0A090"))
            }
        }
        .frame(width: 140)
        .padding(14)
        .background(Color(hex: "#2D1F15"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "#3D2A1A"), lineWidth: 1)
        )
    }
}

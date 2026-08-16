import SwiftUI

struct ScanResultView: View {
    let result: ScanResult
    let onRetry: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showCatalogDetail = false

    private var db: PodDatabase { PodDatabase.shared }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#1A0F0A")
                    .ignoresSafeArea()

                if let pod = result.matchedPod, result.identificationResult.confidence > 0.3 {
                    identifiedPodView(pod: pod)
                } else {
                    unidentifiedView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#C8860A"))
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Identified Pod View

    @ViewBuilder
    private func identifiedPodView(pod: Pod) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                podHeader(pod: pod)

                // Body content
                VStack(alignment: .leading, spacing: 24) {
                    // Tasting notes
                    tastingNotesSection(pod: pod)

                    // Intensity meter
                    intensitySection(pod: pod)

                    // Origin & Roast
                    originSection(pod: pod)

                    // Brew Tips
                    brewTipsSection(pod: pod)

                    // Recipes
                    let recipes = db.recipes(forPod: pod)
                    if !recipes.isEmpty {
                        recipesSection(recipes: recipes)
                    }

                    // View in Catalog button
                    Button(action: { showCatalogDetail = true }) {
                        HStack {
                            Image(systemName: "books.vertical")
                            Text("View Full Profile in Catalog")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#2D1F15"))
                        .foregroundColor(Color(hex: "#C8860A"))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "#C8860A").opacity(0.4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 24)
            }
        }
        .background(Color(hex: "#1A0F0A"))
        .sheet(isPresented: $showCatalogDetail) {
            if let pod = result.matchedPod {
                PodDetailView(pod: pod)
            }
        }
    }

    // MARK: - Pod Header

    @ViewBuilder
    private func podHeader(pod: Pod) -> some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: pod.color).opacity(0.8),
                            Color(hex: "#1A0F0A")
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 200)

            VStack(alignment: .leading, spacing: 12) {
                // Confidence badge
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color(hex: "#C8860A"))
                        .font(.system(size: 14))
                    Text("\(Int(result.identificationResult.confidence * 100))% match")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#C8860A"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.4))
                .cornerRadius(20)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pod.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        HStack(spacing: 8) {
                            lineBadge(pod: pod)
                            intensityBadge(pod: pod)
                        }
                    }

                    Spacer()

                    Circle()
                        .fill(Color(hex: pod.color))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: Color(hex: pod.color).opacity(0.6), radius: 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func tastingNotesSection(pod: Pod) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Tasting Notes")
            wrappingPillsView(notes: pod.tastingNotes)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func intensitySection(pod: Pod) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Intensity")
                Spacer()
                Text("\(pod.intensity)/13")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#C8860A"))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#2D1F15"))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#C8A96E"),
                                    Color(hex: "#3D1A08")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(pod.intensity) / 13.0,
                            height: 12
                        )
                }
            }
            .frame(height: 12)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func originSection(pod: Pod) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Origin & Roast")
            VStack(spacing: 0) {
                infoRow(icon: "globe", label: "Origin", value: pod.origin)
                Divider()
                    .background(Color(hex: "#2D1F15"))
                infoRow(icon: "flame", label: "Roast", value: pod.roast)
                Divider()
                    .background(Color(hex: "#2D1F15"))
                infoRow(icon: "cup.and.saucer", label: "Cup Size", value: pod.recommendedCupSize)
                Divider()
                    .background(Color(hex: "#2D1F15"))
                infoRow(icon: "thermometer", label: "Brew Temp", value: pod.brewTemp)
            }
            .background(Color(hex: "#2D1F15"))
            .cornerRadius(16)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func brewTipsSection(pod: Pod) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Brew Tips")
            VStack(alignment: .leading, spacing: 8) {
                Text(pod.description)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#B0A090"))
                    .lineSpacing(4)

                Text(pod.aromaProfile)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#C8860A"))
                    .padding(.top, 4)
            }
            .padding(16)
            .background(Color(hex: "#2D1F15"))
            .cornerRadius(16)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func recipesSection(recipes: [Recipe]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Try These Recipes")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recipes) { recipe in
                        recipeCard(recipe: recipe)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private func recipeCard(recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recipe.emoji)
                .font(.system(size: 36))

            Text(recipe.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)

            HStack(spacing: 6) {
                Text(recipe.difficulty)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: recipe.difficultyColor).opacity(0.25))
                    .foregroundColor(Color(hex: recipe.difficultyColor))
                    .cornerRadius(8)

                Text(recipe.prepTime)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#B0A090"))
            }
        }
        .frame(width: 150)
        .padding(16)
        .background(Color(hex: "#2D1F15"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#3D2A1A"), lineWidth: 1)
        )
    }

    // MARK: - Unidentified View

    private var unidentifiedView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#2D1F15"))
                        .frame(width: 120, height: 120)
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 56))
                        .foregroundColor(Color(hex: "#B0A090"))
                }

                VStack(spacing: 12) {
                    Text("Pod Not Recognized")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text(result.identificationResult.notes.isEmpty ?
                         "Try again with better lighting and hold the pod steady in the viewfinder." :
                         result.identificationResult.notes)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#B0A090"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if !result.identificationResult.colorObserved.isEmpty &&
                        result.identificationResult.colorObserved != "Unknown" {
                        Text("Observed: \(result.identificationResult.colorObserved) pod")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#C8860A"))
                    }
                }
            }

            VStack(spacing: 12) {
                Button(action: {
                    dismiss()
                    onRetry()
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Try Again")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#C8860A"))
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .cornerRadius(16)
                }

                Button(action: { dismiss() }) {
                    Text("Browse Catalog Instead")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#2D1F15"))
                        .foregroundColor(Color(hex: "#B0A090"))
                        .font(.system(size: 16))
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Helper Views

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color(hex: "#B0A090"))
            .textCase(.uppercase)
            .tracking(1.5)
    }

    private func lineBadge(pod: Pod) -> some View {
        Text(pod.line)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(pod.lineColor.opacity(0.3))
            .foregroundColor(pod.lineColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(pod.lineColor.opacity(0.5), lineWidth: 1)
            )
    }

    private func intensityBadge(pod: Pod) -> some View {
        Text(pod.intensityLabel)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(hex: "#2D1F15"))
            .foregroundColor(Color(hex: "#C8860A"))
            .cornerRadius(8)
    }

    private func wrappingPillsView(notes: [String]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(notes, id: \.self) { note in
                Text(note)
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
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

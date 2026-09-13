import SwiftUI

struct ScanResultView: View {
    let result: ScanResult
    let onRetry: () -> Void

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showCatalogDetail = false
    @State private var recentlySavedPodIds: Set<String> = []
    @State private var didShowSavedConfirmation = false
    @State private var didAttemptAutoSave = false
    @State private var showSaveSheet = false
    @State private var podToSave: Pod? = nil
    @State private var saveNoteText = ""

    private var db: PodDatabase { PodDatabase.shared }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#FFFFFF")
                    .ignoresSafeArea()

                if let pod = result.matchedPod, result.identificationResult.confidence > 0.3 {
                    identifiedPodView(pod: pod)
                } else if result.identificationResult.podName != nil && result.identificationResult.confidence > 0.3 {
                    aiIdentifiedView
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
                    .foregroundColor(Color(hex: "#B97812"))
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showSaveSheet) {
            saveSheet
        }
        .onAppear {
            autoSaveScanIfNeeded()
        }
    }

    // MARK: - Identified Pod View

    @ViewBuilder
    private func identifiedPodView(pod: Pod) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                podHeader(pod: pod)

                VStack(alignment: .leading, spacing: 24) {
                    tastingNotesSection(pod: pod)
                    intensitySection(pod: pod)
                    originSection(pod: pod)
                    brewTipsSection(pod: pod)

                    let recipes = db.recipes(forPod: pod)
                    if !recipes.isEmpty {
                        recipesSection(recipes: recipes)
                    }

                    Button(action: { showCatalogDetail = true }) {
                        HStack {
                            Image(systemName: "books.vertical")
                            Text("View Full Profile in Catalog")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .foregroundColor(Color(hex: "#B97812"))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "#B97812").opacity(0.4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)

                    saveScanButton(pod: pod)
                        .padding(.bottom, 40)
                }
                .padding(.top, 24)
            }
        }
        .background(Color(hex: "#FEF3E2"))
        .sheet(isPresented: $showCatalogDetail) {
            PodDetailView(pod: pod)
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
                            Color(hex: "#FFFFFF")
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 200)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color(hex: "#B97812"))
                        .font(.system(size: 14))
                    Text("\(Int(result.identificationResult.confidence * 100))% match")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#B97812"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.92))
                .cornerRadius(20)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pod.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "#222222"))

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
                Text("\(pod.intensity)/\(pod.intensityScale)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#B97812"))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#FFFFFF"))
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
                            width: geo.size.width * CGFloat(pod.intensity) / CGFloat(pod.intensityScale),
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
                    .background(Color.white)
                infoRow(icon: "flame", label: "Roast", value: pod.roast)
                Divider()
                    .background(Color.white)
                infoRow(icon: "cup.and.saucer", label: "Cup Size", value: pod.recommendedCupSize)
                Divider()
                    .background(Color.white)
                infoRow(icon: "thermometer", label: "Brew Temp", value: pod.brewTemp)
            }
            .background(Color.white)
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
                    .foregroundColor(Color(hex: "#717171"))
                    .lineSpacing(4)

                Text(pod.aromaProfile)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#B97812"))
                    .padding(.top, 4)
            }
            .padding(16)
            .background(Color.white)
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
            HStack {
                Text(recipe.emoji)
                    .font(.system(size: 36))

                Spacer()

                Button {
                    appState.toggleSavedRecipe(recipe.id)
                } label: {
                    Image(systemName: appState.isRecipeSaved(recipe.id) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#B97812"))
                }
                .buttonStyle(.plain)
            }

            Text(recipe.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#222222"))
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
                    .foregroundColor(Color(hex: "#717171"))
            }
        }
        .frame(width: 150)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#F7F7F7"), lineWidth: 1)
        )
    }

    // MARK: - AI Identified View (found by AI but not in local DB)

    private var aiIdentifiedView: some View {
        let ai = result.identificationResult
        return ScrollView {
            VStack(spacing: 0) {

                // Header
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color(hex: "#F7F7F7"), Color(hex: "#FFFFFF")],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 200)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                            Text("\(Int(ai.confidence * 100))% AI Match")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "#B97812"))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.white.opacity(0.92))
                        .cornerRadius(20)

                        Text(ai.podName ?? "Unidentified Pod")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(Color(hex: "#222222"))

                        HStack(spacing: 8) {
                            if let system = ai.podSystem {
                                Text(system)
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color(hex: "#B97812").opacity(0.2))
                                    .foregroundColor(Color(hex: "#B97812"))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#B97812").opacity(0.4), lineWidth: 1))
                            }
                            if let roast = ai.roastLevel {
                                Text(roast + " Roast")
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.white)
                                    .foregroundColor(Color(hex: "#717171"))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 20)
                }

                VStack(alignment: .leading, spacing: 24) {

                    // Flavor notes
                    if !ai.flavorNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("Tasting Notes")
                            wrappingPillsView(notes: ai.flavorNotes)
                        }
                        .padding(.horizontal, 20)
                    }

                    // About this pod
                    if let story = ai.productStory {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionTitle("About This Blend")
                            Text(story)
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "#717171"))
                                .lineSpacing(4)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Brand story
                    if let brand = ai.brandStory {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionTitle("About the Brand")
                            Text(brand)
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "#717171"))
                                .lineSpacing(4)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Details grid
                    VStack(spacing: 0) {
                        if let brand = ai.brand {
                            infoRow(icon: "tag", label: "Brand", value: brand)
                            Divider().background(Color(hex: "#F7F7F7"))
                        }
                        if let system = ai.podSystem {
                            infoRow(icon: "capsule", label: "Pod Type", value: system)
                            Divider().background(Color(hex: "#F7F7F7"))
                        }
                        if let roast = ai.roastLevel {
                            infoRow(icon: "flame", label: "Roast", value: roast + " Roast")
                            Divider().background(Color(hex: "#F7F7F7"))
                        }
                        if let origin = ai.origin {
                            infoRow(icon: "globe", label: "Origin", value: origin)
                            Divider().background(Color(hex: "#F7F7F7"))
                        }
                        if !ai.colorObserved.isEmpty && ai.colorObserved != "Unknown" {
                            infoRow(icon: "paintpalette", label: "Pod Color", value: ai.colorObserved)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // Compatible machines
                    if !ai.compatibleWith.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("Compatible With")
                            wrappingPillsView(notes: ai.compatibleWith)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Extra AI notes
                    if !ai.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle("Additional Info")
                            Text(ai.notes)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#717171"))
                                .lineSpacing(4)
                                .padding(14)
                                .background(Color.white)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button(action: { dismiss(); onRetry() }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Scan Again")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#B97812"))
                            .foregroundColor(Color(hex: "#FFFFFF"))
                            .font(.system(size: 16, weight: .semibold))
                            .cornerRadius(16)
                        }
                        Button(action: { dismiss() }) {
                            Text("Browse Catalog")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .foregroundColor(Color(hex: "#717171"))
                                .font(.system(size: 16))
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 24)
            }
        }
    }

    // MARK: - Unidentified View

    private var unidentifiedView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#FFFFFF"))
                        .frame(width: 120, height: 120)
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 56))
                        .foregroundColor(Color(hex: "#717171"))
                }

                VStack(spacing: 12) {
                    Text("Pod Not Recognized")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "#222222"))

                    Text(result.identificationResult.notes.isEmpty ?
                         "Try again with better lighting and hold the pod steady in the viewfinder." :
                         result.identificationResult.notes)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#717171"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if !result.identificationResult.colorObserved.isEmpty &&
                        result.identificationResult.colorObserved != "Unknown" {
                        Text("Observed: \(result.identificationResult.colorObserved) pod")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#B97812"))
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
                    .background(Color(hex: "#B97812"))
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .cornerRadius(16)
                }

                Button(action: { dismiss() }) {
                    Text("Browse Catalog Instead")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .foregroundColor(Color(hex: "#717171"))
                        .font(.system(size: 16))
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Save Scan

    private func saveScanButton(pod: Pod) -> some View {
        let alreadySaved = recentlySavedPodIds.contains(pod.id)

        return Button {
            guard !alreadySaved else { return }
            guard appState.requireAuthForSave() else { return }
            podToSave = pod
            saveNoteText = ""
            showSaveSheet = true
        } label: {
            HStack {
                Image(systemName: alreadySaved ? "checkmark.circle.fill" : "tray.and.arrow.down.fill")
                Text(didShowSavedConfirmation ? "Saved" : (alreadySaved ? "Saved Automatically" : "Save This Scan"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(alreadySaved ? Color(hex: "#F7F7F7") : Color(hex: "#B97812"))
            .foregroundColor(alreadySaved ? Color(hex: "#717171") : Color(hex: "#FFFFFF"))
            .font(.system(size: 16, weight: .semibold))
            .cornerRadius(16)
        }
        .disabled(alreadySaved)
        .padding(.horizontal, 20)
    }

    // MARK: - Save Sheet

    private var saveSheet: some View {
        NavigationView {
            ZStack {
                Color(hex: "#FFFFFF").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    if let pod = podToSave {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color(hex: pod.color))
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1.5))
                                .shadow(color: Color(hex: pod.color).opacity(0.5), radius: 8)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(pod.name)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "#222222"))
                                Text("\(pod.displayLine) · Intensity \(pod.intensity)")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "#717171"))
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(14)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ADD A NOTE (OPTIONAL)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#717171"))
                            .tracking(1)

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $saveNoteText)
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "#222222"))
                                .padding(12)
                                .frame(minHeight: 110)
                                .background(Color.white)
                                .cornerRadius(14)
                                .scrollContentBackground(.hidden)

                            if saveNoteText.isEmpty {
                                Text("Your impressions, who you made it for, brew tips...")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "#717171").opacity(0.5))
                                    .padding(20)
                                    .allowsHitTesting(false)
                            }
                        }
                    }

                    Spacer()

                    Button {
                        performSave()
                    } label: {
                        Text("Save to Collection")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#B97812"))
                            .foregroundColor(Color(hex: "#FFFFFF"))
                            .font(.system(size: 16, weight: .semibold))
                            .cornerRadius(16)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Save Scan")
            .navigationBarTitleDisplayMode(.inline)


            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showSaveSheet = false
                        podToSave = nil
                        saveNoteText = ""
                    }
                    .foregroundColor(Color(hex: "#717171"))
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.light)
    }

    private func autoSaveScanIfNeeded() {
        guard !didAttemptAutoSave else { return }
        didAttemptAutoSave = true

        guard let scan = automaticSavedScan() else { return }
        appState.saveScan(scan, requireAuthentication: false)

        if let podId = scan.podId {
            recentlySavedPodIds.insert(podId)
        }
        didShowSavedConfirmation = true
    }

    private func automaticSavedScan() -> SavedScan? {
        if let pod = result.matchedPod, result.identificationResult.confidence > 0.3 {
            return SavedScan(
                id: UUID(),
                date: Date(),
                podName: pod.name,
                podId: pod.id,
                podColor: pod.color,
                confidence: result.identificationResult.confidence,
                line: pod.displayLine,
                intensity: pod.intensity
            )
        }

        let ai = result.identificationResult
        guard let podName = ai.podName, ai.confidence > 0.3 else { return nil }

        return SavedScan(
            id: UUID(),
            date: Date(),
            podName: podName,
            podId: nil,
            podColor: "#B97812",
            confidence: ai.confidence,
            line: ai.podSystem ?? "AI Identified",
            intensity: 0
        )
    }

    private func performSave() {
        guard let pod = podToSave else { return }

        var initialNotes: [ScanNote] = []
        let trimmed = saveNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            initialNotes = [ScanNote(id: UUID(), date: Date(), text: trimmed)]
        }

        let scan = SavedScan(
            id: UUID(),
            date: Date(),
            podName: pod.name,
            podId: pod.id,
            podColor: pod.color,
            confidence: result.identificationResult.confidence,
            line: pod.displayLine,
            intensity: pod.intensity,
            notes: initialNotes
        )

        appState.saveScan(scan)
        recentlySavedPodIds.insert(pod.id)
        didShowSavedConfirmation = true
        showSaveSheet = false
        podToSave = nil
        saveNoteText = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            didShowSavedConfirmation = false
        }
    }

    // MARK: - Helper Views

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color(hex: "#717171"))
            .textCase(.uppercase)
            .tracking(1.5)
    }

    private func lineBadge(pod: Pod) -> some View {
        Text(pod.displayLine)
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
            .background(Color.white)
            .foregroundColor(Color(hex: "#B97812"))
            .cornerRadius(8)
    }

    private func wrappingPillsView(notes: [String]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(notes, id: \.self) { note in
                Text(note)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .foregroundColor(Color(hex: "#B97812"))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "#B97812").opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#B97812"))
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#717171"))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#222222"))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

import SwiftUI

struct CatalogView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var selectedPod: Pod?

    private let db = PodDatabase.shared
    private let filters = ["All", "Original", "Vertuo", "Light (1-4)", "Medium (5-7)", "Intense (8+)"]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var filteredPods: [Pod] {
        var pods: [Pod]

        if !searchText.isEmpty {
            pods = db.pods(matching: searchText)
        } else {
            pods = db.allPods()
        }

        switch selectedFilter {
        case "Original":
            pods = pods.filter { $0.line == "Original" }
        case "Vertuo":
            pods = pods.filter { $0.line == "Vertuo" }
        case "Light (1-4)":
            pods = pods.filter { $0.intensity <= 4 }
        case "Medium (5-7)":
            pods = pods.filter { $0.intensity >= 5 && $0.intensity <= 7 }
        case "Intense (8+)":
            pods = pods.filter { $0.intensity >= 8 }
        default:
            break
        }

        return pods
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#1A0F0A")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    // Filter chips
                    filterChipsView

                    // Results count
                    HStack {
                        Text("\(filteredPods.count) pods")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#B0A090"))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)

                    // Pod grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredPods) { pod in
                                PodCard(pod: pod)
                                    .onTapGesture {
                                        selectedPod = pod
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Pod Catalog")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#1A0F0A"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedPod) { pod in
                PodDetailView(pod: pod)
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(hex: "#B0A090"))
                .font(.system(size: 16))

            TextField("", text: $searchText)
                .placeholder(when: searchText.isEmpty) {
                    Text("Search pods, origins, flavors...")
                        .foregroundColor(Color(hex: "#B0A090").opacity(0.6))
                }
                .foregroundColor(.white)
                .font(.system(size: 16))

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(hex: "#B0A090"))
                }
            }
        }
        .padding(14)
        .background(Color(hex: "#2D1F15"))
        .cornerRadius(14)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Filter Chips

    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    FilterChip(
                        title: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Color(hex: "#1A0F0A") : Color(hex: "#B0A090"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "#C8860A") : Color(hex: "#2D1F15"))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.clear : Color(hex: "#3D2A1A"),
                            lineWidth: 1
                        )
                )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Pod Card

struct PodCard: View {
    @EnvironmentObject var appState: AppState
    let pod: Pod
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Color circle and line badge
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: pod.color).opacity(0.9),
                                    Color(hex: pod.color).opacity(0.5)
                                ]),
                                center: .center,
                                startRadius: 5,
                                endRadius: 28
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: Color(hex: pod.color).opacity(0.4), radius: 8, x: 0, y: 4)

                    // Nespresso capsule shape hint
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 18, height: 26)
                        .rotationEffect(.degrees(0))
                }

                Spacer()

                HStack(alignment: .top, spacing: 8) {
                    Button {
                        appState.toggleFavoritePod(pod.id)
                    } label: {
                        Image(systemName: appState.isPodFavorite(pod.id) ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#C8860A"))
                            .frame(width: 30, height: 30)
                            .background(Color(hex: "#1A0F0A"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(pod.line)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(pod.line == "Original" ? Color(hex: "#E87070") : Color(hex: "#6DBF8A"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                (pod.line == "Original" ? Color(hex: "#8B1A1A") : Color(hex: "#1A4D2E")).opacity(0.3)
                            )
                            .cornerRadius(6)

                        Text("\(pod.intensity)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#C8860A"))
                    }
                }
            }

            // Pod name
            Text(pod.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Intensity label
            Text(pod.intensityLabel)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#B0A090"))

            // Mini intensity bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#1A0F0A"))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#C8A96E"), Color(hex: "#3D1A08")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(pod.intensity) / 13.0,
                            height: 4
                        )
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .background(Color(hex: "#2D1F15"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#3D2A1A"), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Placeholder modifier

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

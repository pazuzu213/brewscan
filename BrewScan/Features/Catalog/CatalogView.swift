import SwiftUI

struct CatalogView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var selectedPod: Pod?

    private let db = PodDatabase.shared
    private let filters = ["All", "Nespresso", "Keurig", "Original", "Vertuo", "Light", "Medium", "Intense"]

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
        case "Nespresso":
            pods = pods.filter { $0.systemName == "Nespresso" }
        case "Keurig":
            pods = pods.filter { $0.systemName == "Keurig" }
        case "Original":
            pods = pods.filter { $0.line == "Original" }
        case "Vertuo":
            pods = pods.filter { $0.line == "Vertuo" }
        case "Light":
            pods = pods.filter { $0.intensity <= 4 }
        case "Medium":
            pods = pods.filter { $0.intensity >= 5 && $0.intensity <= 7 }
        case "Intense":
            pods = pods.filter { $0.intensity >= 8 }
        default:
            break
        }

        return pods
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#FFFFFF")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    filterChipsView

                    HStack {
                        Text("\(filteredPods.count) pods")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#717171"))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredPods) { pod in
                                PodCard(pod: pod)
                                    .onTapGesture { selectedPod = pod }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Pod Catalog")
            .navigationBarTitleDisplayMode(.large)
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
                .foregroundColor(Color(hex: "#717171"))
                .font(.system(size: 16))

            TextField("", text: $searchText)
                .placeholder(when: searchText.isEmpty) {
                    Text("Search pods, origins, flavors...")
                        .foregroundColor(Color(hex: "#717171").opacity(0.7))
                }
                .foregroundColor(Color(hex: "#222222"))
                .font(.system(size: 16))
                .onSubmit { hideKeyboard() }

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(hex: "#717171"))
                }
            }
        }
        .padding(14)
        .background(.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 1)
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
                .foregroundColor(isSelected ? .white : Color(hex: "#717171"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "#B97812") : Color(hex: "#F7F7F7"))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.clear : Color(hex: "#E5DDD5"),
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
                        .shadow(color: Color(hex: pod.color).opacity(0.3), radius: 8, x: 0, y: 4)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 18, height: 26)
                }

                Spacer()

                HStack(alignment: .top, spacing: 8) {
                    Button {
                        appState.toggleFavoritePod(pod.id)
                    } label: {
                        Image(systemName: appState.isPodFavorite(pod.id) ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#B97812"))
                            .frame(width: 30, height: 30)
                            .background(Color(hex: "#FEF3E2"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(pod.displayLine)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(pod.lineColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(pod.lineColor.opacity(0.15))
                            .cornerRadius(6)

                        Text("\(pod.intensity)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#B97812"))
                    }
                }
            }

            Text(pod.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#222222"))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(pod.intensityLabel)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#717171"))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#EBEBEB"))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#C8A96E"), Color(hex: "#8B5A2B")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(pod.intensity) / CGFloat(pod.intensityScale),
                            height: 4
                        )
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
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

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

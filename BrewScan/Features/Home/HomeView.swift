import SwiftUI
import UIKit

extension Notification.Name {
    static let brewScanSelectTab = Notification.Name("brewScanSelectTab")
}

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedScan: SavedScan? = nil

    private var recentScans: [SavedScan] {
        Array(appState.savedScans.sorted { $0.date > $1.date }.prefix(5))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#FFFFFF")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header
                        statsRow
                        recentScansSection
                        scanButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 36)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedScan) { scan in
                SavedScanDetailView(scan: scan)
                    .environmentObject(appState)
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "#222222"))
                    .lineLimit(2)

                Text("Ready to discover your next favourite pod?")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#717171"))
            }

            Spacer()

            Button {
                NotificationCenter.default.post(name: .brewScanSelectTab, object: 4)
            } label: {
                Text(initials)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(Color(hex: "#B97812"))
                    .clipShape(Circle())
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(title: "Scans", value: "\(appState.savedScans.count)")
            statCard(title: "Recipes saved", value: "\(appState.savedRecipeIds.count)")
            statCard(title: "Favourites", value: "\(appState.favoritePodIds.count)")
        }
    }

    private var recentScansSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Scans")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "#222222"))

                Spacer()

                Button("See All") {
                    NotificationCenter.default.post(name: .brewScanSelectTab, object: 4)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#B97812"))
            }

            if recentScans.isEmpty {
                Text("No scans yet — point your camera at a pod!")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#717171"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color(hex: "#F7F7F7"))
                    .cornerRadius(16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentScans) { scan in
                            recentScanCard(scan)
                                .onTapGesture { selectedScan = scan }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var scanButton: some View {
        Button {
            NotificationCenter.default.post(name: .brewScanSelectTab, object: 2)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                Text("Scan a Pod")
            }
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(hex: "#B97812"))
            .foregroundColor(.white)
            .cornerRadius(24)
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: "#222222"))

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "#717171"))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func recentScanCard(_ scan: SavedScan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
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
                    .shadow(color: Color(hex: scan.podColor).opacity(0.4), radius: 6)

                Spacer()

                Text("\(Int(scan.confidence * 100))%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#B97812"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#FEF3E2"))
                    .cornerRadius(12)
            }

            Text(scan.podName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#222222"))
                .lineLimit(2)

            Text(scan.date.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#717171"))

            if let rating = scan.rating {
                Text(String(repeating: "★", count: rating))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#B97812"))
            }
        }
        .frame(width: 170, alignment: .leading)
        .padding(14)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = appState.userProfile?.name.split(separator: " ").first.map(String.init) ?? "there"
        let dayPart: String

        switch hour {
        case 5..<12:
            dayPart = "Good morning"
        case 12..<17:
            dayPart = "Good afternoon"
        default:
            dayPart = "Good evening"
        }

        return "\(dayPart), \(name) ☕"
    }

    private var initials: String {
        guard let name = appState.userProfile?.name, !name.isEmpty else { return "PS" }
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }.map(String.init)
        return letters.joined().uppercased()
    }
}

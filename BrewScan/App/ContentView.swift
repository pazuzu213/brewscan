import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 1

    var body: some View {
        if !appState.hasCompletedOnboarding {
            WelcomeView()
        } else {
            mainTabView
                .sheet(isPresented: $appState.isShowingAuth) {
                    AuthView()
                        .environmentObject(appState)
                }
        }
    }

    var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            CatalogView()
                .tabItem { Label("Catalog", systemImage: "books.vertical.fill") }
                .tag(1)

            ScannerView()
                .tabItem { Label("Scan", systemImage: "camera.fill") }
                .tag(2)

            RecipesView()
                .tabItem { Label("Recipes", systemImage: "cup.and.saucer.fill") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Library", systemImage: "tray.full.fill") }
                .tag(4)
        }
        .accentColor(Color(hex: "#B97812"))
        .preferredColorScheme(.light)
        .onReceive(NotificationCenter.default.publisher(for: .brewScanSelectTab)) { notification in
            if let tab = notification.object as? Int {
                selectedTab = tab
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}

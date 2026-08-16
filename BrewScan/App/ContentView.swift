import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            // Catalog tab
            CatalogView()
                .tabItem {
                    Label("Catalog", systemImage: "books.vertical.fill")
                }
                .tag(0)

            // Scanner tab (center)
            ScannerView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(1)

            // Recipes tab
            RecipesView()
                .tabItem {
                    Label("Recipes", systemImage: "cup.and.saucer.fill")
                }
                .tag(2)
        }
        .accentColor(Color(hex: "#C8860A"))
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}

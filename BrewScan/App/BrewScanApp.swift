import SwiftUI

@main
struct BrewScanApp: App {
    @StateObject private var appState = AppState.shared

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    appState.handleMagicLink(url)
                }
        }
    }

    private func configureAppearance() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .white
        navBarAppearance.shadowColor = UIColor(red: 0.91, green: 0.89, blue: 0.86, alpha: 1.0)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0)]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0)]

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0.73, green: 0.47, blue: 0.07, alpha: 1.0)

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .white
        tabBarAppearance.shadowColor = UIColor(red: 0.90, green: 0.88, blue: 0.85, alpha: 1.0)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(red: 0.73, green: 0.47, blue: 0.07, alpha: 1.0)
        UITabBar.appearance().unselectedItemTintColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
    }
}

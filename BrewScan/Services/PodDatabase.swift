import Foundation

class PodDatabase: ObservableObject {
    static let shared = PodDatabase()

    private var pods: [Pod] = []
    private var recipes: [Recipe] = []

    private init() {
        loadData()
    }

    private func loadData() {
        pods = loadJSON(filename: "pods", type: [Pod].self) ?? []
        recipes = loadJSON(filename: "recipes", type: [Recipe].self) ?? []
    }

    private func loadJSON<T: Decodable>(filename: String, type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("BrewScan: Could not find \(filename).json in bundle")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("BrewScan: Failed to decode \(filename).json: \(error)")
            return nil
        }
    }

    // MARK: - Pod Methods

    func allPods() -> [Pod] {
        pods
    }

    func pod(byId id: String) -> Pod? {
        pods.first { $0.id == id }
    }

    func pods(matching query: String) -> [Pod] {
        guard !query.isEmpty else { return pods }
        let lowercasedQuery = query.lowercased()
        return pods.filter { pod in
            pod.name.lowercased().contains(lowercasedQuery) ||
            pod.line.lowercased().contains(lowercasedQuery) ||
            pod.roast.lowercased().contains(lowercasedQuery) ||
            pod.origin.lowercased().contains(lowercasedQuery) ||
            pod.tastingNotes.contains { $0.lowercased().contains(lowercasedQuery) } ||
            pod.intensityLabel.lowercased().contains(lowercasedQuery)
        }
    }

    func pods(forLine line: String) -> [Pod] {
        guard line != "All" else { return pods }
        return pods.filter { $0.line == line }
    }

    func pods(forIntensityRange range: ClosedRange<Int>) -> [Pod] {
        pods.filter { range.contains($0.intensity) }
    }

    // MARK: - Recipe Methods

    func allRecipes() -> [Recipe] {
        recipes
    }

    func recipe(byId id: String) -> Recipe? {
        recipes.first { $0.id == id }
    }

    func recipes(forPod pod: Pod) -> [Recipe] {
        recipes.filter { pod.recipeIds.contains($0.id) }
    }

    func pods(forRecipe recipe: Recipe) -> [Pod] {
        pods.filter { recipe.compatiblePodIds.contains($0.id) }
    }
}

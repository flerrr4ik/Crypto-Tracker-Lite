import Foundation

class FavoritesManager {
    static let shared = FavoritesManager()

    private let key = "favorites"

    private init() {}

    var favoriteIds: Set<String> {
        get {
            return Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: key)
        }
    }

    func addFavorite(id: String) {
        var favorites = favoriteIds
        favorites.insert(id)
        favoriteIds = favorites
    }

    func removeFavorite(id: String) {
        var favorites = favoriteIds
        favorites.remove(id)
        favoriteIds = favorites
    }

    func isFavorite(id: String) -> Bool {
        return favoriteIds.contains(id)
    }
}

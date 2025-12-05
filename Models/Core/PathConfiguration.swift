import Foundation

/// Manages custom project path configuration
class PathConfiguration: ObservableObject {
    @Published var customPaths: [URL] = []

    private let userDefaultsKey = "custom_project_paths"

    init() {
        loadPaths()
    }

    // MARK: - Path Management

    func addPath(_ url: URL) throws {
        // Validate path
        guard validatePath(url) else {
            throw PathError.invalidPath(url.path)
        }

        // Check for duplicates
        if customPaths.contains(where: { $0.path == url.path }) {
            throw PathError.duplicatePath(url.path)
        }

        customPaths.append(url)
        persistPaths()
    }

    func removePath(_ url: URL) {
        customPaths.removeAll { $0.path == url.path }
        persistPaths()
    }

    func validatePath(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return false
        }
        return isDirectory.boolValue
    }

    // MARK: - Persistence

    private func loadPaths() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let paths = try? JSONDecoder().decode([String].self, from: data) {
            customPaths = paths.compactMap { URL(fileURLWithPath: $0) }
        }
    }

    private func persistPaths() {
        let paths = customPaths.map { $0.path }
        if let data = try? JSONEncoder().encode(paths) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    enum PathError: LocalizedError {
        case invalidPath(String)
        case duplicatePath(String)
        case notDirectory(String)

        var errorDescription: String? {
            switch self {
            case .invalidPath(let path):
                return "Invalid path: \(path) does not exist"
            case .duplicatePath(let path):
                return "Path already added: \(path)"
            case .notDirectory(let path):
                return "Not a directory: \(path)"
            }
        }
    }
}

import Foundation

enum AppVersionInfo {
    static let version = "0.1.9"
    static let build = 10
    static let releaseKind = "prerelease"
    static let releaseDate = "2026-06-11"
    static let authorURL = URL(string: "https://github.com/lferrarezi") ?? URL(fileURLWithPath: "/")
    static let repositoryURL = URL(string: "https://github.com/lferrarezi/Palm-Sync") ?? URL(fileURLWithPath: "/")

    static var displayVersion: String {
        "\(version) (\(releaseKind))"
    }
}

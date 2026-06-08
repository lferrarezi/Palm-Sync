import Foundation

enum AppVersionInfo {
    static let version = "0.1.1"
    static let build = 2
    static let releaseKind = "prerelease"
    static let releaseDate = "2026-06-08"

    static var displayVersion: String {
        "\(version) (\(releaseKind))"
    }
}

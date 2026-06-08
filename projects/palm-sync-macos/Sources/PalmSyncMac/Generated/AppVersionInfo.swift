import Foundation

enum AppVersionInfo {
    static let version = "0.1.0"
    static let build = 1
    static let releaseKind = "prerelease"
    static let releaseDate = "2026-06-07"

    static var displayVersion: String {
        "\(version) (\(releaseKind))"
    }
}


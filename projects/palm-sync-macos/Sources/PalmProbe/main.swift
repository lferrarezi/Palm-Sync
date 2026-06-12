import Foundation

struct ProbeResult: Codable {
    var generatedAt: Date
    var serialPorts: [String]
    var usbPalmHints: [String]

    var likelyReadyForHotSync: Bool {
        !serialPorts.isEmpty || !usbPalmHints.isEmpty
    }
}

struct ProbeComparison: Codable {
    var generatedAt: Date
    var before: ProbeResult
    var after: ProbeResult
    var addedSerialPorts: [String]
    var removedSerialPorts: [String]
    var addedUSBHints: [String]
    var removedUSBHints: [String]

    var hasNewPalmSignals: Bool {
        !addedSerialPorts.isEmpty || !addedUSBHints.isEmpty
    }
}

enum ProbeCommand {
    case capture(json: Bool, output: URL?)
    case compare(before: URL, after: URL, json: Bool, output: URL?)
    case session(device: String, outputDirectory: URL)
    case help
}

@main
struct PalmProbe {
    static func main() {
        do {
            try run(parseCommand())
        } catch {
            fputs("palm-probe error: \(error.localizedDescription)\n", stderr)
            Foundation.exit(1)
        }
    }

    private static func run(_ command: ProbeCommand) throws {
        switch command {
        case let .capture(json, output):
            let result = runProbe()
            try write(result, json: json, output: output)

        case let .compare(beforeURL, afterURL, json, output):
            let comparison = try compare(beforeURL: beforeURL, afterURL: afterURL)
            try write(comparison, json: json, output: output)

        case let .session(device, outputDirectory):
            try createSession(device: device, outputDirectory: outputDirectory)

        case .help:
            printUsage()
        }
    }

    private static func parseCommand() -> ProbeCommand {
        var arguments = Array(CommandLine.arguments.dropFirst())
        let json = consumeFlag("--json", from: &arguments)

        if arguments.isEmpty {
            return .capture(json: json, output: nil)
        }

        let subcommand = arguments.removeFirst()
        switch subcommand {
        case "capture":
            return .capture(json: json, output: consumeOutput(from: &arguments))

        case "compare":
            guard arguments.count >= 2 else { return .help }
            let before = URL(fileURLWithPath: arguments.removeFirst())
            let after = URL(fileURLWithPath: arguments.removeFirst())
            return .compare(before: before, after: after, json: json, output: consumeOutput(from: &arguments))

        case "session":
            let device = sanitizeDeviceName(consumeValue("--device", from: &arguments) ?? "unknown-palm")
            let output = consumeValue("--output-dir", from: &arguments) ?? "diagnostics/\(device)"
            return .session(device: device, outputDirectory: URL(fileURLWithPath: output))

        case "--help", "help":
            return .help

        default:
            return .capture(json: json, output: consumeOutput(from: &arguments))
        }
    }

    private static func runProbe() -> ProbeResult {
        ProbeResult(
            generatedAt: Date(),
            serialPorts: serialCandidates(),
            usbPalmHints: usbHints()
        )
    }

    private static func compare(beforeURL: URL, afterURL: URL) throws -> ProbeComparison {
        let before = try readProbeResult(from: beforeURL)
        let after = try readProbeResult(from: afterURL)
        return ProbeComparison(
            generatedAt: Date(),
            before: before,
            after: after,
            addedSerialPorts: added(from: before.serialPorts, to: after.serialPorts),
            removedSerialPorts: removed(from: before.serialPorts, to: after.serialPorts),
            addedUSBHints: added(from: before.usbPalmHints, to: after.usbPalmHints),
            removedUSBHints: removed(from: before.usbPalmHints, to: after.usbPalmHints)
        )
    }

    private static func createSession(device: String, outputDirectory: URL) throws {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let readmeURL = outputDirectory.appendingPathComponent("README.md")
        let beforeURL = outputDirectory.appendingPathComponent("before.json")
        let afterURL = outputDirectory.appendingPathComponent("after.json")
        let comparisonURL = outputDirectory.appendingPathComponent("comparison.json")

        let readme = """
        # Palm Sync Diagnostics: \(device)

        1. Disconnect the Palm or leave it idle before HotSync.
        2. Run:
           `swift run palm-probe capture --json --output \(beforeURL.path)`
        3. Connect the Palm and press HotSync.
        4. Run:
           `swift run palm-probe capture --json --output \(afterURL.path)`
        5. Compare:
           `swift run palm-probe compare \(beforeURL.path) \(afterURL.path) --json --output \(comparisonURL.path)`

        Device: \(device)
        Created: \(Date().formatted(date: .abbreviated, time: .standard))
        """

        try readme.write(to: readmeURL, atomically: true, encoding: .utf8)
        print("Created diagnostic session:")
        print("  \(outputDirectory.path)")
        print("")
        print("Next:")
        print("  swift run palm-probe capture --json --output \(beforeURL.path)")
    }

    private static func write(_ result: ProbeResult, json: Bool, output: URL?) throws {
        if json || output != nil {
            try writeJSON(result, output: output)
            return
        }

        print("Palm Sync palm-probe")
        print("====================")
        print("Generated: \(result.generatedAt.formatted(date: .abbreviated, time: .standard))")
        print("")
        printList("Serial ports", values: result.serialPorts, empty: "none")
        print("")
        printList("USB hints", values: result.usbPalmHints, empty: "no Palm-like USB device found in system_profiler output")
        print("")
        print("Status:")
        print(result.likelyReadyForHotSync ? "  possible Palm connection detected" : "  no Palm connection detected yet")
        print("")
        print("Tip:")
        print("  Use `swift run palm-probe capture --json --output before.json` before pressing HotSync.")
    }

    private static func write(_ comparison: ProbeComparison, json: Bool, output: URL?) throws {
        if json || output != nil {
            try writeJSON(comparison, output: output)
            return
        }

        print("Palm Sync palm-probe compare")
        print("============================")
        print("Generated: \(comparison.generatedAt.formatted(date: .abbreviated, time: .standard))")
        print("")
        printList("Added serial ports", values: comparison.addedSerialPorts, empty: "none")
        printList("Removed serial ports", values: comparison.removedSerialPorts, empty: "none")
        printList("Added USB hints", values: comparison.addedUSBHints, empty: "none")
        printList("Removed USB hints", values: comparison.removedUSBHints, empty: "none")
        print("")
        print("Status:")
        print(comparison.hasNewPalmSignals ? "  new Palm-like signals detected" : "  no new Palm-like signals detected")
    }

    private static func writeJSON<T: Encodable>(_ value: T, output: URL?) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)

        if let output {
            try FileManager.default.createDirectory(
                at: output.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: output)
            print("Wrote \(output.path)")
            return
        }

        FileHandle.standardOutput.write(data)
        print("")
    }

    private static func readProbeResult(from url: URL) throws -> ProbeResult {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ProbeResult.self, from: data)
    }

    private static func printList(_ title: String, values: [String], empty: String) {
        print("\(title):")
        if values.isEmpty {
            print("  \(empty)")
        } else {
            values.forEach { print("  \($0)") }
        }
    }

    private static func serialCandidates() -> [String] {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(atPath: "/dev") else {
            return []
        }

        return entries
            .filter { entry in
                entry.hasPrefix("cu.") && (
                    entry.localizedCaseInsensitiveContains("usb") ||
                    entry.localizedCaseInsensitiveContains("serial") ||
                    entry.localizedCaseInsensitiveContains("palm") ||
                    entry.localizedCaseInsensitiveContains("modem")
                )
            }
            .sorted()
            .map { "/dev/\($0)" }
    }

    private static func usbHints() -> [String] {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPUSBDataType", "-detailLevel", "mini", "-timeout", "15"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return ["system_profiler unavailable: \(error.localizedDescription)"]
        }

        // Drain the pipe before waiting, otherwise a full pipe buffer deadlocks both processes.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        return output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { line in
                line.localizedCaseInsensitiveContains("palm") ||
                line.localizedCaseInsensitiveContains("handspring") ||
                line.localizedCaseInsensitiveContains("sony") ||
                line.localizedCaseInsensitiveContains("serial")
            }
    }

    private static func sanitizeDeviceName(_ name: String) -> String {
        let mapped = name.lowercased().map { character -> Character in
            character.isLetter || character.isNumber || character == "-" ? character : "-"
        }
        let cleaned = String(mapped).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return cleaned.isEmpty ? "unknown-palm" : cleaned
    }

    private static func added(from before: [String], to after: [String]) -> [String] {
        Array(Set(after).subtracting(Set(before))).sorted()
    }

    private static func removed(from before: [String], to after: [String]) -> [String] {
        Array(Set(before).subtracting(Set(after))).sorted()
    }

    private static func consumeFlag(_ flag: String, from arguments: inout [String]) -> Bool {
        if let index = arguments.firstIndex(of: flag) {
            arguments.remove(at: index)
            return true
        }
        return false
    }

    private static func consumeValue(_ key: String, from arguments: inout [String]) -> String? {
        guard let index = arguments.firstIndex(of: key), arguments.indices.contains(index + 1) else {
            return nil
        }
        arguments.remove(at: index)
        return arguments.remove(at: index)
    }

    private static func consumeOutput(from arguments: inout [String]) -> URL? {
        guard let path = consumeValue("--output", from: &arguments) else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }

    private static func printUsage() {
        print("""
        Palm Sync palm-probe

        Usage:
          swift run palm-probe
          swift run palm-probe capture [--json] [--output path.json]
          swift run palm-probe compare before.json after.json [--json] [--output comparison.json]
          swift run palm-probe session --device lifedrive --output-dir diagnostics/lifedrive

        Recommended flow:
          1. Run capture before pressing HotSync.
          2. Press HotSync on the Palm.
          3. Run capture again.
          4. Run compare on the two JSON files.
        """)
    }
}


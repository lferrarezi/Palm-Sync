import Foundation

struct ProbeResult: Codable {
    var generatedAt: Date
    var serialPorts: [String]
    var usbPalmHints: [String]
    var likelyReadyForHotSync: Bool {
        !serialPorts.isEmpty || !usbPalmHints.isEmpty
    }
}

@main
struct PalmProbe {
    static func main() {
        let arguments = Set(CommandLine.arguments.dropFirst())
        let result = runProbe()

        if arguments.contains("--json") {
            printJSON(result)
            return
        }

        print("Palm Sync palm-probe")
        print("====================")
        print("Generated: \(result.generatedAt.formatted(date: .abbreviated, time: .standard))")
        print("")
        print("Serial ports:")
        if result.serialPorts.isEmpty {
            print("  none")
        } else {
            result.serialPorts.forEach { print("  \($0)") }
        }

        print("")
        print("USB hints:")
        if result.usbPalmHints.isEmpty {
            print("  no Palm-like USB device found in system_profiler output")
        } else {
            result.usbPalmHints.forEach { print("  \($0)") }
        }

        print("")
        print("Status:")
        if result.likelyReadyForHotSync {
            print("  possible Palm connection detected")
        } else {
            print("  no Palm connection detected yet")
        }

        print("")
        print("Next:")
        print("  1. Put the Palm in the cradle or connect the cable.")
        print("  2. Press HotSync on the device/cradle.")
        print("  3. Re-run palm-probe and compare ports.")
        print("")
        print("Tip:")
        print("  Use `swift run palm-probe --json` to save a machine-readable report.")
    }

    private static func runProbe() -> ProbeResult {
        let serialPorts = serialCandidates()
        let usbHints = usbHints()
        return ProbeResult(generatedAt: Date(), serialPorts: serialPorts, usbPalmHints: usbHints)
    }

    private static func printJSON(_ result: ProbeResult) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(result)
            if let output = String(data: data, encoding: .utf8) {
                print(output)
            }
        } catch {
            fputs("failed to encode probe report: \(error.localizedDescription)\n", stderr)
            Foundation.exit(1)
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
        process.arguments = ["SPUSBDataType", "-detailLevel", "mini"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ["system_profiler unavailable: \(error.localizedDescription)"]
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
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
}

import Foundation

struct ProbeResult {
    var serialPorts: [String]
    var usbPalmHints: [String]
}

@main
struct PalmProbe {
    static func main() {
        let result = runProbe()
        print("PalmIsAlive palm-probe")
        print("======================")
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
        print("Next:")
        print("  1. Put the Palm in the cradle or connect the cable.")
        print("  2. Press HotSync on the device/cradle.")
        print("  3. Re-run palm-probe and compare ports.")
    }

    private static func runProbe() -> ProbeResult {
        let serialPorts = serialCandidates()
        let usbHints = usbHints()
        return ProbeResult(serialPorts: serialPorts, usbPalmHints: usbHints)
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


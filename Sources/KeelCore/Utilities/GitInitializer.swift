import Foundation

public enum GitInitializer {
    public struct CommandError: LocalizedError {
        let command: String
        let output: String
        public var errorDescription: String? { "`git \(command)` failed: \(output)" }
    }

    /// Creates a repository on `main` with an initial commit.
    public static func initialize(at directory: URL) throws {
        try run(["init", "--initial-branch=main"], in: directory)
        try run(["add", "--all"], in: directory)
        try run(["commit", "--message", "Initial commit"], in: directory)
    }

    private static func run(_ arguments: [String], in directory: URL) throws {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw CommandError(
                command: arguments.joined(separator: " "),
                output: String(decoding: output, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }
}

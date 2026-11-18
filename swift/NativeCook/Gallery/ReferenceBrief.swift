import Foundation
import zlib

struct ReferenceBrief {
    let markdown: String
    private let images: [(path: String, data: Data)]

    init(draft: ReferenceDraft) {
        var lines = ["# Native Cook reference"]
        var images: [(path: String, data: Data)] = []

        if let direction = Self.nonempty(draft.direction) {
            lines += ["", "## Target direction", "", Self.quote(direction)]
        }

        lines += ["", "**SwiftUI source revision** `\(ReferenceCatalog.sourceRevision)`", "", "## Examples"]

        for (index, entry) in draft.entries.enumerated() {
            let example = ReferenceCatalog.bySlug[entry.slug]
            let starter = ReferenceCatalog.starters[entry.slug]
            lines += ["", "### \(index + 1). \(Self.escape(example?.name ?? entry.slug))", "", "**Slug** `\(entry.slug)`"]

            if let example {
                lines += ["", "**Source** `\(example.sourcePath)`"]
                if let cue = Self.nonempty(starter?.cue ?? example.spec) {
                    lines += ["", "**Cue** \(Self.escape(cue))"]
                }
                if let trigger = starter?.trigger {
                    lines += ["", "**Trigger** \(Self.escape(trigger))"]
                }
            } else {
                lines += ["", "This demo is unavailable in the current SwiftUI catalog."]
            }

            if let takeaway = Self.nonempty(entry.takeaway) {
                lines += ["", "**Takeaway**", "", Self.quote(takeaway)]
            }

            if let starter {
                let frames = [(starter.poster, "Poster"), (starter.motionFrame, "Second motion state")]
                for (filename, label) in frames {
                    guard let filename,
                          let url = ReferenceCatalog.mediaURL(filename),
                          let data = try? Data(contentsOf: url) else { continue }
                    let path = "images/\(filename)"
                    images.append((path, data))
                    lines += ["", "![\(label)](\(path))"]
                }
            }
        }

        self.markdown = lines.joined(separator: "\n") + "\n"
        self.images = images
    }

    func writeArchive() throws -> URL {
        let folder = URL.temporaryDirectory.appending(path: "Native Cook Reference", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appending(path: "Native Cook Reference.zip")
        var archive = StoredZIP()
        try archive.append(path: "Reference.md", contents: Data(markdown.utf8))
        for image in images {
            try archive.append(path: image.path, contents: image.data)
        }
        try archive.finish().write(to: file, options: .atomic)
        return file
    }

    private static func nonempty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func quote(_ text: String) -> String {
        text.components(separatedBy: .newlines)
            .map { "> " + escape($0) }
            .joined(separator: "\n")
    }

    private static func escape(_ text: String) -> String {
        let punctuation: Set<Character> = ["\\", "`", "*", "_", "{", "}", "[", "]", "<", ">", "#", "|", "&"]
        return text.reduce(into: "") { result, character in
            if punctuation.contains(character) { result.append("\\") }
            result.append(character)
        }
    }
}

// Classic ZIP with stored entries. The bundled JPEGs are already compressed.
private struct StoredZIP {
    enum Failure: Error { case tooLarge }

    private var archive = Data()
    private var directory = Data()
    private var count: UInt16 = 0

    mutating func append(path: String, contents: Data) throws {
        let name = Data(path.utf8)
        guard let offset = UInt32(exactly: archive.count),
              let size = UInt32(exactly: contents.count),
              let nameLength = UInt16(exactly: name.count),
              count < .max else { throw Failure.tooLarge }
        let checksum = contents.withUnsafeBytes {
            UInt32(crc32(0, $0.bindMemory(to: UInt8.self).baseAddress, size))
        }

        var fields = Data()
        fields.appendLE(UInt16(20)) // Version needed.
        fields.appendLE(UInt16(0x0800)) // UTF-8 filenames.
        fields.appendLE(UInt16(0)) // Store.
        fields.appendLE(UInt16(0)) // DOS time, midnight.
        fields.appendLE(UInt16(33)) // DOS date, January 1, 1980.
        fields.appendLE(checksum)
        fields.appendLE(size)
        fields.appendLE(size)
        fields.appendLE(nameLength)
        fields.appendLE(UInt16(0)) // Extra length.

        archive.appendLE(UInt32(0x04034b50))
        archive.append(fields)
        archive.append(name)
        archive.append(contents)

        directory.appendLE(UInt32(0x02014b50))
        directory.appendLE(UInt16(20)) // Version made by.
        directory.append(fields)
        directory.append(Data(repeating: 0, count: 10)) // Comment, disk and attributes.
        directory.appendLE(offset)
        directory.append(name)
        count += 1
    }

    mutating func finish() throws -> Data {
        guard let directoryOffset = UInt32(exactly: archive.count),
              let directorySize = UInt32(exactly: directory.count) else { throw Failure.tooLarge }
        archive.append(directory)
        archive.appendLE(UInt32(0x06054b50))
        archive.appendLE(UInt16(0)) // Disk number.
        archive.appendLE(UInt16(0)) // Central directory disk.
        archive.appendLE(count)
        archive.appendLE(count)
        archive.appendLE(directorySize)
        archive.appendLE(directoryOffset)
        archive.appendLE(UInt16(0)) // Comment length.
        return archive
    }
}

private extension Data {
    mutating func appendLE(_ value: some FixedWidthInteger) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }
}

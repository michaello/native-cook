import Foundation
import Observation
import SwiftUI

struct ReferenceDraft: Codable, Equatable {
    struct Entry: Codable, Equatable, Identifiable {
        let slug: String
        var takeaway = ""

        var id: String { slug }
    }

    var direction = ""
    var entries: [Entry] = []
}

@MainActor
@Observable
final class ReferenceDraftStore {
    private let file: URL
    private(set) var draft = ReferenceDraft()
    private(set) var storageError: String?
    private var canWrite = true

    init(file: URL? = nil) {
        let support = URL.applicationSupportDirectory
        let destination = file ?? support.appending(path: "ReferenceDraft.json")
        #if DEBUG
        let defaults = UserDefaults.standard
        let testID = defaults.string(forKey: "referenceDraftTestID").flatMap(UUID.init(uuidString:))
        let seedMissing = testID != nil && defaults.bool(forKey: "referenceDraftSeedMissing")
        self.file = testID.map { support.appending(path: "ReferenceDraftTests/\($0.uuidString).json") } ?? destination
        #else
        self.file = destination
        #endif

        do {
            draft = try JSONDecoder().decode(ReferenceDraft.self, from: Data(contentsOf: self.file))
            var seen = Set<String>()
            draft.entries = draft.entries.filter { seen.insert($0.slug).inserted }
        } catch CocoaError.fileReadNoSuchFile {
            #if DEBUG
            if seedMissing { add("unavailable-test-demo") }
            #endif
        } catch {
            canWrite = false
            storageError = "The saved draft couldn’t be read. Its original file has been kept."
        }
    }

    func contains(_ slug: String) -> Bool {
        draft.entries.contains { $0.slug == slug }
    }

    func add(_ slug: String) {
        guard !contains(slug) else { return }
        update { $0.entries.append(.init(slug: slug)) }
    }

    func remove(_ slug: String) {
        update { $0.entries.removeAll { $0.slug == slug } }
    }

    func move(from offsets: IndexSet, to index: Int) {
        update { $0.entries.move(fromOffsets: offsets, toOffset: index) }
    }

    func setDirection(_ text: String) {
        update { $0.direction = text }
    }

    func takeaway(for slug: String) -> String {
        draft.entries.first { $0.slug == slug }?.takeaway ?? ""
    }

    func setTakeaway(_ text: String, for slug: String) {
        guard let index = draft.entries.firstIndex(where: { $0.slug == slug }) else { return }
        update { $0.entries[index].takeaway = text }
    }

    private func update(_ change: (inout ReferenceDraft) -> Void) {
        guard canWrite else { return }
        var updated = draft
        change(&updated)
        guard updated != draft else { return }

        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(updated).write(to: file, options: .atomic)
            draft = updated
            storageError = nil
        } catch {
            storageError = "The change couldn’t be saved. Try again after checking available storage."
        }
    }
}

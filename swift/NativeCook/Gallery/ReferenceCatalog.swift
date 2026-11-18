import Foundation

struct ReferenceEntry: Decodable {
    let slug: String
    let name: String
    let category: String
    let spec: String
    let sourcePath: String
}

struct ReferenceStarter: Decodable {
    let theme: String
    let purpose: String
    let fullScreen: Bool
    let keywords: [String]
    let cue: String
    let poster: String
    let motionFrame: String?
    let trigger: String?
}

enum ReferenceCatalog {
    private struct Catalog: Decodable {
        let sourceRevision: String
        let entries: [ReferenceEntry]
    }

    private static let catalog = load(Catalog.self, resource: "ReferenceCatalog")
    static let sourceRevision = catalog?.sourceRevision ?? ""
    static let bySlug = Dictionary(uniqueKeysWithValues: (catalog?.entries ?? []).map { ($0.slug, $0) })
    static let starters = load([String: ReferenceStarter].self, resource: "ReferenceStarters") ?? [:]
    static let themes = ["Layered depth", "Tactile materials", "Reveals"]
    static let categories = Set(blockRegistry.map(\.category)).sorted()
    static let purposes = Set(starters.values.map(\.purpose)).sorted()

    static func mediaURL(_ filename: String) -> URL? {
        Bundle.main.url(forResource: filename, withExtension: nil)
    }

    private struct SearchRow {
        let block: Block
        let name: String
        let aliases: [String]
        let searchable: String
    }

    private static let searchRows = blockRegistry.map { block in
        let starter = starters[block.slug]
        let name = normalize(block.name)
        let aliases = (starter?.keywords ?? []).map { normalize($0) }
        let fields = [
            normalize(block.slug), name, normalize(block.category), normalize(block.spec),
            normalize(starter?.theme ?? ""), normalize(starter?.cue ?? ""), normalize(starter?.trigger ?? "")
        ] + aliases
        return SearchRow(block: block, name: name, aliases: aliases, searchable: fields.joined(separator: " "))
    }

    static func search(_ query: String, category: String?, purpose: String?, fullScreen: Bool?) -> [Block] {
        let phrase = normalize(query)
        let terms = phrase.split(separator: " ")
        let slug = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var buckets = Array(repeating: [Block](), count: 5)
        for row in searchRows {
            let block = row.block
            let starter = starters[block.slug]
            guard category == nil || category == block.category,
                  purpose == nil || purpose == starter?.purpose,
                  fullScreen == nil || fullScreen == starter?.fullScreen else { continue }
            guard terms.allSatisfy({ row.searchable.contains($0) }) else { continue }

            let rank: Int
            if block.slug == slug {
                rank = 0
            } else if row.aliases.contains(phrase) {
                rank = 1
            } else if !phrase.isEmpty && row.name.contains(phrase) {
                rank = 2
            } else if !phrase.isEmpty && row.searchable.contains(phrase) {
                rank = 3
            } else {
                rank = 4
            }
            buckets[rank].append(block)
        }
        return buckets.flatMap { $0 }
    }

    private static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .joined(separator: " ")
    }

    private static func load<T: Decodable>(_ type: T.Type, resource: String) -> T? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else { return nil }
        do {
            return try JSONDecoder().decode(type, from: Data(contentsOf: url))
        } catch {
            assertionFailure("Invalid bundled reference metadata: \(resource): \(error)")
            return nil
        }
    }
}

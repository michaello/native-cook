import SwiftUI
import UIKit

struct ReferenceDraftScreen: View {
    let store: ReferenceDraftStore
    let onOpen: (Block, [Block]) -> Void

    @State private var archive: SharedArchive?
    @State private var showsShareError = false
    @State private var copied = false
    @Environment(\.dismiss) private var dismiss

    private static let blocks = Dictionary(uniqueKeysWithValues: blockRegistry.map { ($0.slug, $0) })

    var body: some View {
        NavigationStack {
            List {
                if let error = store.storageError {
                    Text(error).foregroundStyle(GalleryColors.accent)
                }

                Section("Target direction") {
                    TextField("What should these examples inform?", text: direction, axis: .vertical)
                        .lineLimit(2...5)
                        .accessibilityIdentifier("draft.direction")
                }
                .listRowBackground(GalleryColors.surface)

                Section("Examples") {
                    if store.draft.entries.isEmpty {
                        ContentUnavailableView(
                            "No examples yet",
                            systemImage: "rectangle.stack",
                            description: Text("Add demos from Explore or Favorites.")
                        )
                        .accessibilityIdentifier("draft.empty")
                    }

                    ForEach(store.draft.entries) { entry in
                        row(entry)
                    }
                    .onMove(perform: store.move)
                    .onDelete { offsets in
                        let slugs = offsets.map { store.draft.entries[$0].slug }
                        slugs.forEach(store.remove)
                    }
                }
                .listRowBackground(GalleryColors.surface)

                if !store.draft.entries.isEmpty {
                    Section {
                        Button {
                            UIPasteboard.general.string = ReferenceBrief(draft: store.draft).markdown
                            copied = true
                        } label: {
                            Label(copied ? "Markdown copied" : "Copy Markdown", systemImage: copied ? "checkmark" : "doc.on.doc")
                        }
                        .accessibilityIdentifier("draft.copy")

                        Button {
                            do {
                                archive = try SharedArchive(url: ReferenceBrief(draft: store.draft).writeArchive())
                            } catch {
                                showsShareError = true
                            }
                        } label: {
                            Label("Share ZIP", systemImage: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("draft.share")
                    }
                    .listRowBackground(GalleryColors.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(GalleryColors.background)
            .navigationTitle("Reference draft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: { dismiss() })
                        .accessibilityIdentifier("draft.close")
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                        .accessibilityIdentifier("draft.edit")
                        .disabled(store.draft.entries.isEmpty)
                }
            }
            .onChange(of: store.draft) { _, _ in copied = false }
            .sheet(item: $archive) { item in
                ArchiveShareSheet(url: item.url)
            }
            .alert("Couldn’t prepare the ZIP", isPresented: $showsShareError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your draft is still saved. Try sharing again.")
            }
        }
        .tint(GalleryColors.accent)
    }

    private var direction: Binding<String> {
        Binding(get: { store.draft.direction }, set: store.setDirection)
    }

    private func row(_ entry: ReferenceDraft.Entry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let block = Self.blocks[entry.slug] {
                Button {
                    let order = store.draft.entries.compactMap { Self.blocks[$0.slug] }
                    onOpen(block, order)
                } label: {
                    HStack {
                        Text(block.name).font(.headline)
                        Spacer()
                        Image(systemName: "play.circle")
                    }
                    .foregroundStyle(GalleryColors.text)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("draft.open.\(entry.slug)")
            } else {
                Text(entry.slug)
                    .font(.headline)
                Text("Unavailable in this version of the SwiftUI catalog.")
                    .font(.subheadline)
                    .foregroundStyle(GalleryColors.textMuted)
                    .accessibilityIdentifier("draft.unavailable.\(entry.slug)")
            }

            TextField(
                "Takeaway (optional)",
                text: Binding(
                    get: { store.takeaway(for: entry.slug) },
                    set: { store.setTakeaway($0, for: entry.slug) }
                ),
                axis: .vertical
            )
            .font(.subheadline)
            .lineLimit(1...4)
            .accessibilityIdentifier("draft.takeaway.\(entry.slug)")
        }
        .padding(.vertical, 4)
    }
}

private struct SharedArchive: Identifiable {
    let url: URL
    var id: URL { url }
}

private struct ArchiveShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

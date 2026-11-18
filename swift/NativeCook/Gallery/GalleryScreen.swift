import SwiftUI
import UIKit

struct GalleryScreen: View {
    let favorites: Set<String>
    let draft: ReferenceDraftStore
    let onOpen: (Block, [Block]) -> Void

    private enum Scope: String, CaseIterable {
        case explore = "Explore"
        case all = "All"
        case favorites = "Favorites"
    }

    @State private var scope = Scope.explore
    @State private var query = ""
    @State private var category: String?
    @State private var purpose: String?
    @State private var fullScreen: Bool?
    @State private var showingDraft = false
    @FocusState private var searchFocused: Bool

    @ScaledMetric(relativeTo: .body) private var cardWidth = 152

    private var hasSearch: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || category != nil || purpose != nil || fullScreen != nil
    }

    var body: some View {
        VStack(spacing: 12) {
            header.padding(.horizontal, 16)
            ScrollViewReader { proxy in
                ScrollView {
                    Color.clear.frame(height: 1).id("galleryTop")
                    content
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: scope) { _, _ in proxy.scrollTo("galleryTop", anchor: .top) }
                .onChange(of: query) { _, _ in proxy.scrollTo("galleryTop", anchor: .top) }
                .onChange(of: category) { _, _ in proxy.scrollTo("galleryTop", anchor: .top) }
                .onChange(of: purpose) { _, _ in proxy.scrollTo("galleryTop", anchor: .top) }
                .onChange(of: fullScreen) { _, _ in proxy.scrollTo("galleryTop", anchor: .top) }
            }
        }
        .padding(.top, 8)
        .background(GalleryColors.background.ignoresSafeArea())
        .sheet(isPresented: $showingDraft) {
            ReferenceDraftScreen(store: draft) { block, order in
                showingDraft = false
                onOpen(block, order)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Native Cook")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    searchFocused = false
                    showingDraft = true
                } label: {
                    Label("Draft", systemImage: "rectangle.stack")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(GalleryColors.surface, in: Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(GalleryColors.accent)
                .accessibilityIdentifier("gallery.draft")
            }
            Picker("Show blocks", selection: $scope) {
                ForEach(Scope.allCases, id: \.self) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("blocks.filter")

            if scope == .explore {
                searchBar
                facets
            }
        }
        .foregroundStyle(GalleryColors.text)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(GalleryColors.textMuted)
                .accessibilityHidden(true)
            TextField("Search SwiftUI demos", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($searchFocused)
                .onSubmit { searchFocused = false }
                .accessibilityIdentifier("reference.search")
            if !query.isEmpty {
                Button("Clear search", systemImage: "xmark.circle.fill") { query = "" }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(GalleryColors.textMuted)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("reference.clear")
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
        .background(GalleryColors.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var facets: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                facet("Category", selection: $category, options: ReferenceCatalog.categories)
                facet("Purpose", selection: $purpose, options: ReferenceCatalog.purposes)
                Menu {
                    Picker("Scale", selection: $fullScreen) {
                        Text("Any scale").tag(Bool?.none)
                        Text("Full screen").tag(Bool?.some(true))
                        Text("Focused interaction").tag(Bool?.some(false))
                    }
                } label: {
                    facetLabel(fullScreen.map { $0 ? "Full screen" : "Focused interaction" } ?? "Scale", active: fullScreen != nil)
                }
                .accessibilityIdentifier("reference.scale")
            }
        }
        .scrollIndicators(.hidden)
    }

    private func facet(_ title: String, selection: Binding<String?>, options: [String]) -> some View {
        Menu {
            Picker(title, selection: selection) {
                Text("Any \(title.lowercased())").tag(String?.none)
                ForEach(options, id: \.self) { option in
                    Text(option).tag(String?.some(option))
                }
            }
        } label: {
            facetLabel(selection.wrappedValue ?? title, active: selection.wrappedValue != nil)
        }
        .accessibilityIdentifier("reference.\(title.lowercased())")
    }

    private func facetLabel(_ text: String, active: Bool) -> some View {
        Label(text, systemImage: "chevron.down")
            .labelStyle(.titleAndIcon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(active ? GalleryColors.accent : GalleryColors.text)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(GalleryColors.surface, in: Capsule())
    }

    @ViewBuilder
    private var content: some View {
        switch scope {
        case .explore:
            if hasSearch {
                let results = ReferenceCatalog.search(query, category: category, purpose: purpose, fullScreen: fullScreen)
                if results.isEmpty {
                    ContentUnavailableView("No demos found", systemImage: "magnifyingglass")
                } else {
                    grid(results, order: results)
                }
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(ReferenceCatalog.themes, id: \.self) { theme in
                        let blocks = blockRegistry.filter { ReferenceCatalog.starters[$0.slug]?.theme == theme }
                        if !blocks.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(theme).font(.title3.bold()).accessibilityAddTraits(.isHeader)
                                grid(blocks, order: blocks)
                            }
                        }
                    }
                    Button("Browse all \(blockRegistry.count) SwiftUI demos") {
                        scope = .all
                    }
                    .foregroundStyle(GalleryColors.accent)
                    .frame(minHeight: 44)
                }
            }
        case .all:
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(Self.groups) { group in
                    Section {
                        grid(group.blocks, order: blockRegistry)
                    } header: {
                        Text(group.category).font(.title3.bold()).accessibilityAddTraits(.isHeader)
                    }
                }
            }
        case .favorites:
            let blocks = blockRegistry.filter { favorites.contains($0.slug) }
            if blocks.isEmpty {
                ContentUnavailableView(
                    "No favorites yet",
                    systemImage: "heart",
                    description: Text("Open a demo and tap its heart to save it here.")
                )
            } else {
                grid(blocks, order: blocks)
            }
        }
    }

    private func grid(_ blocks: [Block], order: [Block]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: cardWidth), spacing: 12)], spacing: 12) {
            ForEach(blocks) { block in
                ReferenceCard(block: block, favorite: favorites.contains(block.slug), added: draft.contains(block.slug)) {
                    searchFocused = false
                    onOpen(block, order)
                } onAdd: {
                    draft.add(block.slug)
                }
            }
        }
    }

    private struct Group: Identifiable {
        let category: String
        var blocks: [Block]
        var id: String { category }
    }

    private static let groups: [Group] = ReferenceCatalog.categories.map { category in
        Group(category: category, blocks: blockRegistry.filter { $0.category == category })
    }
}

private struct ReferenceCard: View {
    let block: Block
    let favorite: Bool
    let added: Bool
    let onOpen: () -> Void
    let onAdd: () -> Void

    private var starter: ReferenceStarter? { ReferenceCatalog.starters[block.slug] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 0) {
                    if let poster = starter?.poster,
                       let url = ReferenceCatalog.mediaURL(poster),
                       let image = UIImage(contentsOfFile: url.path) {
                        Rectangle()
                            .fill(GalleryColors.background)
                            .aspectRatio(4 / 5.0, contentMode: .fit)
                            .overlay {
                                Image(uiImage: image).resizable().scaledToFill()
                            }
                            .clipped()
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(block.name)
                            .font(.headline)
                            .foregroundStyle(GalleryColors.text)
                        Text(starter?.cue ?? block.spec)
                            .font(.caption)
                            .foregroundStyle(GalleryColors.textMuted)
                            .lineLimit(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("block.\(block.slug)")

            Spacer(minLength: 0)
            HStack {
                Text(block.category)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(GalleryColors.textMuted)
                if favorite {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(.pink)
                        .accessibilityLabel("Favorite")
                }
                Spacer(minLength: 0)
                Button(action: onAdd) {
                    Image(systemName: added ? "checkmark" : "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(added ? GalleryColors.textMuted : GalleryColors.accent)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(added)
                .accessibilityLabel(added ? "Added to draft" : "Add \(block.name) to draft")
                .accessibilityIdentifier("draft.add.\(block.slug)")
            }
            .padding(.leading, 12)
        }
        .background(GalleryColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(GalleryColors.border, lineWidth: 0.5) }
    }
}

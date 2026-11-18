# Native Cook aesthetic reference library

Make every Native Cook demo easy to find and give a coding agent a short, portable brief about which visual or motion qualities to carry into a new design. V1 ships in the Swift iPhone app and makes the repository searchable across SwiftUI, React Native, and Kotlin from a local checkout.

## Product scope

- **Explore** is the default gallery. Show curated examples of layered depth, tactile materials, and reveals, then make every registered demo reachable through search and category browsing. Use a lazy card grid with locally generated stills for the starter set and a usable text treatment for every other demo. Include both full-screen compositions and smaller interactions.
- **Offline search** matches slug, name, category, and the existing description. Keep exact slug hits first, with deterministic ordering. Start with a small, audited set of facets such as category, purpose, and full-screen. Show unclassified entries in unfiltered results and make them findable by text. Treat existing Jev tags as candidates, with confidence reviewed field by field.
- **Live comparison** uses the ordered results from the list that opened the demo, including curated groups, searches, Favorites, and the reference draft. All and a direct `-block <slug>` launch use the full registry. Freeze the ordered list when the demo opens so edits or favorite removal cannot cause a jump. Keep the scrubber's move, dock, scrub, and persistence behavior. Recording remains a clean full-screen stage.
- **Favorites** retain the existing heart and stored slugs. Add a separate, locally saved reference draft. Add examples from Explore and Favorites, prevent duplicates, reorder and remove entries, and capture one target direction plus an optional short takeaway per demo. Show a useful empty state. Explain entries that become unavailable after a catalog update and let the user remove them.
- **Share** exports a ZIP through the iOS share sheet and offers a copyable Markdown brief. The ZIP contains the same brief plus small, available local stills at relative paths. The brief preserves example order and gives each item a name, slug, concrete appearance or motion cue, takeaway when entered, and a resolvable source pointer. Pair motion-centered starter examples with a second visible key state and the trigger. A missing image leaves the text cue and source usable. Share only media captured locally for this purpose and within the approved sharing scope. Store the draft independently from temporary share files.
- **Local agent lookup** provides a checked-in catalog with a single row per slug and verified repository-relative demo paths for each available platform. One documented command searches from a clone without network, credentials, an app build, or an external service. Locate source by a verified revision and path or a canonical block link, and keep paths usable after moving the checkout.

## Implementation boundaries

- Build the app work under `swift/NativeCook/Gallery/` and exercise it through `swift/RecordBlocks/`. Swift remains compatible with its existing iOS 17 deployment target. React Native and Kotlin contribute registry and source metadata for V1.
- The tracked generated registries are authoritative for shipped slugs and demo entry points. At the planning baseline, all three contain the same 825 slugs. Validate the union and available paths at execution time. Join curated metadata by stable slug in a sidecar and keep generation repeatable. The upstream generator input is absent from this checkout. Preserve the existing untracked `index.json`, `scripts/jev-tag-blocks.py`, and handoff notes.
- Use local bundled metadata and assets. Capture through the existing recording launch path on the simulator, with no gallery UI visible. Keep stills small and load each live demo only on demand. Choose a starter set of 12 still-backed blocks across three themes as the implementation default. Give at least three motion-led examples two meaningful frames each.
- V1 covers one reference draft, local lookup, the Swift gallery, and physical iPhone delivery. Future work includes named collections, hosted boards, account or cloud sync, runtime AI tagging, another MCP service, complete preview coverage, gallery changes in the other stacks, and store distribution.
- Use the existing local signing setup for the device build. Use the fork branch `aesthetic-reference` for delivery and follow the user's current-turn PR authorization rule.

## Approved completion criteria

Mike confirmed the iPhone and full local-catalog scope and the end-to-end checks in this conversation.

| ID | Tier | Evidence required |
|---|---|---|
| REF-01 | Local | Regenerate the catalog twice and compare identical output. Validate slug coverage against all three registries and verify that each available platform path resolves to the tracked demo entry point. Run a documented local lookup from a fresh checkout. |
| REF-02 | Local | Capture a curated starter set of clean stills, including three motion examples with a second state and a trigger. Validate each bundled image decodes and all registrations refer to catalog slugs. |
| REF-03 | Local | On the iPhone simulator with no catalog service or network dependency, find relevant demos for three briefs, such as layered glass, tactile scrubbing, and a reveal. Prove exact lookup and opening for an unillustrated demo. Verify a scoped session follows its visible result order and the full catalog remains reachable. |
| REF-04 | Local | Add three demos to one draft, reorder them, add a target direction and a takeaway, relaunch, and confirm order and notes persist. Verify duplicate handling, removal, an empty draft, and a missing-slug case. |
| REF-05 | Local | Share an actual ZIP and copy its brief. Starting independently with the exported ZIP and the available source checkout, extract and read the Markdown, check sequence and notes, resolve every included image and source pointer, and recover the design cues with no access to app state. Include a no-image entry. |
| REF-06 | Local | Build for the simulator. Run the existing scrubber and favorites coverage plus the focused new tests, and run a representative recording test with a usable recording artifact. Verify `-block` still opens the requested demo. |
| REF-07 | Access-gated | Build and strictly verify a signed generic iOS app from the tested source. If provisioning or signing access fails, build generic iOS with signing disabled and record build and simulator proof plus the signing failure. |
| REF-08 | Access-gated | Install the verified build on Mike's iPhone 16 Pro Max, launch it, and match the running executable to the newly installed bundle. If the phone is unavailable, retain the signed artifact when possible and demonstrate the same launch and flow on the simulator. Retry discovery before reporting the phone blocker. |
| REF-09 | Access-gated | Push the completed feature commits to the fork branch and verify its remote SHA. If GitHub rejects or is unreachable, preserve the verified local commit and record the exact remote failure and retry. |

The recipient check is a clean-room reading of the exported reference, rather than a requirement for a particular hosted model or external account. Device signing, the physical phone, and GitHub access affect only their delivery proofs.

## Verification references

- Project `swift/NativeCook.xcodeproj`, scheme `NativeCook`, tests in `swift/RecordBlocks/`.
- Use `xcrun simctl list devices available` to select an iPhone simulator, and the IDE's DerivedData path. Run `xcodebuild -project swift/NativeCook.xcodeproj -scheme NativeCook -destination "platform=iOS Simulator,id=$SIM_ID" -derivedDataPath "$SIM_DERIVED_DATA" -only-testing:RecordBlocks/GalleryControlsTests -parallel-testing-enabled NO test` plus focused new test identifiers.
- A representative recorder check is `TEST_RUNNER_RECORD_SLUGS=gold-dune-contours xcodebuild … -only-testing:RecordBlocks/BlockRecordings/test_gold_dune_contours -parallel-testing-enabled NO test`, using the same project, scheme, destination and DerivedData arguments. Confirm the test executed rather than skipped and inspect the resulting attachment. The exact test class can be checked in `swift/RecordBlocks/Blocks.swift`.
- For phone delivery, read the local iOS runbook. Start with `xcrun devicectl list devices` and use the device info, install, and process launch subcommands. Record proof from the same source revision used for simulator regression checks.

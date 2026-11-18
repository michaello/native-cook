<goal>
Ship the SwiftUI iPhone reference workflow defined in SPEC.md. A user can find any registered SwiftUI demo offline, compare relevant live demos, assemble a persistent reference draft, and share visual and motion cues with a coding agent. The repository provides local lookup and SwiftUI source paths. Verify the feature locally and deliver the tested build to Mike's iPhone and the fork branch.
</goal>

<context>
- Run from the Native Cook repository root. Read SPEC.md and any applicable AGENTS.md. Confirm `git status --short --branch` and inspect the current HEAD before editing. Planning baseline was `54eeb3e1`.
- Start at `swift/NativeCook/Gallery/{Block,BlockRegistry,GalleryScreen,RootView,BlockScrubber,DemoScreen}.swift` and `swift/RecordBlocks/{GalleryControlsTests,Blocks,Recorder}.swift`. Read `swift/NativeCook.xcodeproj/project.pbxproj` for bundle targets and resource handling.
- README.md explains SwiftUI demo entry paths and direct launch. The SwiftUI registry contained 825 slugs at planning time.
- Existing untracked `index.json` covers 797 baseline slugs and contains uncertain, description-derived facets. The accompanying `scripts/jev-tag-blocks.py` uses an external provider for new tags. Read them as local evidence and preserve them. The tracked SwiftUI registry and demo files supply inventory and paths independently of them.
- Read `$HOME/.codex/docs/ios.md` for simulator and physical delivery. Read the earlier handoff if it is present. Treat prior build artifacts, device PIDs, and installed-app UUIDs as historical.
</context>

<constraints>
- Scope is full offline discovery, one persistent ordered draft, Markdown and ZIP export, searchable local metadata for SwiftUI demos, and verified iPhone delivery. Scope changes only when Mike changes it in words. A tool, format, or reporting restriction changes the mechanism while the same scope and queue apply.
- Keep the app, lookup, and exports SwiftUI-only. Retain iOS 17 compatibility and use the SwiftUI registry and existing demo entry points. Add sidecar metadata keyed by slug. Keep gallery searches, draft storage, and export working with local data.
- All registered demos remain findable. The curated starter set contains 12 still-backed blocks across layered depth, tactile materials, and reveals, and includes both screen-scale examples and focused interactions. Add a second frame and a trigger to at least three motion-led examples. Show a text card wherever there is no still. Render live effects on demand.
- Maintain the existing favorites data and grabber gestures. Open a stable, ordered navigation session from the originating list. All and direct launch use global order. Preserve clean recording. Use locally captured media within the approved sharing scope and resolve source pointers without relying on footage, account access, or third-party APIs.
- The scope fence leaves named collections, sync, hosted sharing, new MCP infrastructure, complete still coverage, store distribution, and automated outbound sharing for future work. Use existing product and repo surfaces for the approved functionality. Preserve unrelated untracked files and existing user data.
</constraints>

<done_when>
- REF-01, local. A tracked catalog and documented lookup work in a clean local clone. Generate twice and compare the output byte for byte. Compare its slug set with the SwiftUI registry and verify that each path resolves to the correct tracked SwiftUI demo entry. Check exact slug lookup, duplicate prevention, and a lookup with no results.
- REF-02, local. Record 12 clean demo posters across the three starter themes and verify media links and image decoding for all 12. Confirm three motion examples contain their second distinct state and a trigger cue. Capture via the existing recording mode and verify that the frame excludes gallery controls.
- REF-03, local. On an iPhone simulator, prove that local Explore returns relevant results for three distinct visual briefs, using layered glass, tactile scrubbing, and a reveal as the starting fixtures. Find and open a slug without a poster by exact query. Verify filtered and global navigation order, including the position label and the single-result boundary. Demonstrate that search and launch work without a catalog service or network dependency.
- REF-04, local. From Explore or Favorites, create one draft of three different demos. Reorder it, add a target direction and a takeaway, relaunch, confirm order and text, and exercise duplicate, remove, empty, and missing-slug behavior. Verify heart changes are independent of draft membership.
- REF-05, local. Produce a ZIP through Share and copy its Markdown. Include one example with a motion frame pair and one without a still. The ZIP and copied brief carry the same usable direction, sequence, notes, and SwiftUI source pointers. Extract the ZIP to a clean path, then have a fresh recipient or independent local review consume the archive and a pinned source checkout. Verify every image resolves, retrieve the cue and source for each example, and validate the ZIP with `unzip -t`.
- REF-06, local. On the same source revision as the pilot, run targeted gallery tests and the existing `RecordBlocks/GalleryControlsTests` suite on iPhone simulator. Verify `-block` direct launch and run the representative recorder test. Confirm that the recorder ran and exported a usable attachment.
- REF-07, access-gated by signing and provisioning. Build a signed generic iOS app from the simulator-tested revision, confirm the expected bundle identity, and pass `codesign --verify --deep --strict --verbose=2`. Fallback ladder: inspect build settings and signing diagnostics, retry generic iOS with the existing team and provisioning setup, then build with `CODE_SIGNING_ALLOWED=NO` and record its result and the exact signing failure.
- REF-08, access-gated by the physical phone and a signed artifact. Discover Mike's physical iPhone 16 Pro Max, gracefully terminate the old app if it's running, install the verified build, launch it, and match the running executable to the reported installation path. Fallback ladder: rediscover the paired phone and retry install or launch as appropriate, retain the signed artifact when available, then exercise and verify the same direct launch and reference flow on an iPhone simulator. Record the missing prerequisite and failing output for the physical proof.
- REF-09, access-gated by GitHub write access and reachability. Push the tested implementation to `origin` on `aesthetic-reference` and verify the commit SHA through `git ls-remote --heads origin refs/heads/aesthetic-reference`. Fallback ladder: verify the local commit and configured remotes, fetch and reconcile recoverable divergence without force-pushing, retry the fork push, and retain the tested commit and exact error if the remote remains unavailable.
</done_when>

<work_queue>
- The list and Status field are in this block. Update the Status and Proof cells in GOAL.md as work proceeds. Keep queue updates with the implementation commits and retain detailed logs or artifact paths in the Proof cell. For REF-09, record the verified implementation SHA, then push the final queue update and confirm the branch includes that SHA.
- Statuses are Open, In Progress, Done, and Blocked - External. Use Done only after recording verification. Unfinished work without a recorded external blocker stays Open or In Progress.
- Run this count command from the repository root at the start and end of every turn:

```sh
awk -F '|' '$2 ~ /^ REF-[0-9]+ $/ {gsub(/^ +| +$/, "", $3); count[$3]++} END {n=split("Open,In Progress,Done,Blocked - External", s, ","); for (i=1;i<=n;i++) printf "%s: %d\n", s[i], count[s[i]]}' GOAL.md
```

- Pick the first Open or In Progress item, name it, work it, verify it, then record the result before moving on. Local items come first. Apply each access-gated item's fallback without giving up progress on subsequent items.
- If counts stay identical for two turns, name the stall, pick another executable item, and continue. The scope and queue stay fixed when a tool or output format changes. End each report with counts and the next ID, or the remaining blocked IDs and their failing commands.

| ID | Status | Proof |
|---|---|---|
| REF-01 | Done | 666c4549. Clean clone under /tmp/native-cook-lookup.1QeUJh. Two generations matched each other and tracked JSON. All 825 pinned paths matched declared SwiftUI types. Exact first, duplicate rejected, no-hit exit 1. /tmp/native-cook-reference-proof/catalog.log |
| REF-02 | In Progress | Capturing and validating the starter set in simulator recording mode. |
| REF-03 | Open | |
| REF-04 | Open | |
| REF-05 | Open | |
| REF-06 | Open | |
| REF-07 | Open | |
| REF-08 | Open | |
| REF-09 | Open | |
</work_queue>

<workflow>
1. Read the spec, SwiftUI registry, current gallery and recorder, and confirm the test scheme. Run independent reads together. Confirm starter examples and facet coverage against the current checkout.
2. Implement and validate the local catalog and lookup. Seed verified starter examples and capture their imagery with the simulator and existing recorder entry point. Use a deterministic cue and image mapping for each starter example.
3. Build Explore and scoped playback, then the saved draft and export. Reuse existing navigation hooks, favorite storage, capture flags, and slug identity. Iterate on search fixtures and export failure handling as each local item is verified.
4. Run the integrated simulator checks and export proof. Carry the source revision forward to signing and device delivery. Complete and verify the fork push under the delivery criteria. Record progress and proof in queue order, with independently executable work continuing through external failures.
</workflow>

<verification_loop>
- Run the local catalog generation and lookup checks from a clean checkout or temporary local clone. Verify coverage against the current SwiftUI registry. Validate paths with tracked files, and archive asset paths with a fresh extraction.
- Use `xcrun simctl list devices available` and choose an available iPhone. Set SIM_ID and SIM_DERIVED_DATA to the selected simulator and the project's IDE DerivedData directory. Keep build and test operations that share DerivedData serialized.

```sh
xcodebuild -project swift/NativeCook.xcodeproj -scheme NativeCook -destination "platform=iOS Simulator,id=$SIM_ID" -derivedDataPath "$SIM_DERIVED_DATA" -only-testing:RecordBlocks/GalleryControlsTests -parallel-testing-enabled NO test
TEST_RUNNER_RECORD_SLUGS=gold-dune-contours xcodebuild -project swift/NativeCook.xcodeproj -scheme NativeCook -destination "platform=iOS Simulator,id=$SIM_ID" -derivedDataPath "$SIM_DERIVED_DATA" -only-testing:RecordBlocks/BlockRecordings/test_gold_dune_contours -parallel-testing-enabled NO test
```

- Run the corresponding targeted new test identifiers with the same project, scheme, destination and DerivedData arguments. Use XCTest and simulator CLI for evidence. Confirm outputs exist and record counts, archive contents, simulator identity, and test outcomes. Check `git diff --check`.
- Sign using the existing developer setup, generic iOS destination and a distinct device DerivedData directory. Check the local runbook for project signing overrides and follow the existing `com.test.nativecook` device setup when applicable. Use `xcrun devicectl list devices`, `xcrun devicectl device info apps`, and `xcrun devicectl device info processes` for delivery proof. Put `--` before launch arguments passed to the app.
- Inspect any failing output, fix recoverable errors, and rerun the focused check before advancing that item. Keep cache and saved user data intact.
</verification_loop>

<blocker_policy>
A blocker on one item means you work everything else. The run ends only when every remaining item is a blocker, each with its own failing command and output.
- Scope each blocker to the exact criterion it makes impossible. Split a mixed item on discovery, record the executable part and its proof, and assign Blocked - External to the specific access-gated proof.
- Apply the item's fallback ladder first. Record the exact failure output, missing access, and fallback evidence on that item, then continue with the next executable item in the same turn.
- Signing, phone availability, and GitHub credentials or connectivity are the access gates for REF-07, REF-08, and REF-09, respectively. Keep the local catalog, app, archives, recording, tests, and local commit moving independently. Report one underlying access problem by name wherever separate proofs depend on it.
- Keep implementation and validation on the queue even if release or upload work is easier to run. Recheck every remaining blocked command once before reporting all possible work exhausted. Record the resulting counts, every remaining blocker, and the access needed to clear it. Keep working while any item is executable through local edits, tests, fixtures, or services.
</blocker_policy>

<execution_rules>
- Read files before editing. Check git status, preserve unrelated changes, use rg for discovery, and batch independent reads. Keep edits focused and run targeted checks first. Document actual results.
- Stage only files changed for this task, commit logical units, and push to the named fork branch. A pull request requires Mike's current-turn approval. Preserve current user data, provisioning settings, and DerivedData caches.
- Requested iPhone app work includes signing, graceful termination, installation, launch and runtime verification. Use signing access only for provisioning or signature verification. Use the app and simulator through their CLIs and tests. Follow Mike's current-turn rules for artifact viewers and desktop interaction.
- At the start of each turn, name the next criterion and record its outcome before switching. Handle recoverable failures in the same run. Work through every independently executable item, with the stated fallback evidence for external gates.
</execution_rules>

<output_contract>
Deliver the local catalog and lookup, the Swift app workflow, validated simulator and archive proof, physical install and running identity, and the tested commit on the fork. Give exact paths for local artifacts and report which checks passed, with any remaining specific access gates and their fallback evidence. End each report with counts for all four allowed statuses and the next item ID, or list the remaining blocked IDs with their commands. Mark the goal complete once every criterion is Done.
</output_contract>

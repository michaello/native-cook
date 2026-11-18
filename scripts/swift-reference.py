#!/usr/bin/env python3
"""Generate or search the local Native Cook SwiftUI catalog."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
GALLERY = ROOT / "swift/NativeCook/Gallery"
CATALOG = GALLERY / "ReferenceCatalog.json"
BLOCKS = "swift/NativeCook/Blocks"
SOURCE_REVISION = "54eeb3e1c4f5695e1d95160cbf265cc958f47810"

SWIFT_STRING = r'("(?:[^"\\]|\\.)*")'
REGISTRATION = re.compile(
    r"\s*Block\(slug: " + SWIFT_STRING + ", name: " + SWIFT_STRING
    + ", category: " + SWIFT_STRING + ", spec: " + SWIFT_STRING
    + r"\) \{ AnyView\((\w+)\(\)\) \},?"
)


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True)


def generate():
    tracked = git("ls-files", "-z", "--", BLOCKS).split("\0")
    pinned = set(git("ls-tree", "-rz", "--name-only", SOURCE_REVISION, "--", BLOCKS).split("\0"))
    if git("diff", SOURCE_REVISION, "--", BLOCKS):
        raise ValueError(f"SwiftUI demo sources differ from pinned revision {SOURCE_REVISION}")

    paths = {}
    for filename in tracked:
        path = Path(filename)
        if path.suffix == ".swift":
            paths.setdefault(path.stem, []).append(filename)

    entries = {}
    for line in (GALLERY / "BlockRegistry.swift").read_text().splitlines():
        if not line.lstrip().startswith("Block("):
            continue
        match = REGISTRATION.fullmatch(line)
        if not match:
            raise ValueError(f"Unsupported SwiftUI registration: {line[:140]}")
        slug, name, category, spec = map(json.loads, match.groups()[:4])
        demo = match.group(5)
        if slug in entries:
            raise ValueError(f"Duplicate SwiftUI slug: {slug}")
        candidates = paths.get(demo, [])
        if len(candidates) != 1 or candidates[0] not in pinned:
            raise ValueError(f"{slug} has no unique tracked source at {SOURCE_REVISION}: {candidates}")
        source = candidates[0]
        declaration = rf"^\s*(?:(?:public|internal) )?struct {re.escape(demo)}\b"
        if not re.search(declaration, (ROOT / source).read_text(), re.MULTILINE):
            raise ValueError(f"{source} does not declare {demo}")
        entries[slug] = dict(slug=slug, name=name, category=category, spec=spec, sourcePath=source)

    if not entries:
        raise ValueError("No SwiftUI registrations found")
    return dict(sourceRevision=SOURCE_REVISION, entries=list(entries.values()))


def lookup(entries, query):
    query = query.strip().casefold()
    terms = re.findall(r"\w+", query)
    if not terms:
        return []
    result = []
    for entry in entries:
        fields = " ".join(entry[key] for key in ("slug", "name", "category", "spec")).casefold()
        if entry["slug"] == query or all(term in fields for term in terms):
            result.append(entry)
    return sorted(result, key=lambda entry: entry["slug"] != query)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_subparsers(dest="command", required=True)
    generation = modes.add_parser("generate")
    generation.add_argument("--output", type=Path, default=CATALOG)
    search = modes.add_parser("lookup")
    search.add_argument("query")
    args = parser.parse_args()
    if args.command == "generate":
        output = json.dumps(generate(), ensure_ascii=False, indent=2) + "\n"
        args.output.write_text(output, encoding="utf-8")
        return
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    matches = lookup(catalog["entries"], args.query)
    for entry in matches:
        print(f'{entry["slug"]}\t{entry["name"]}\t{entry["category"]}\t{entry["sourcePath"]}')
    if not matches:
        print("No SwiftUI demos found.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

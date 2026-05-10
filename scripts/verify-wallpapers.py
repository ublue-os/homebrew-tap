#!/usr/bin/env python3
"""
Verify every url/sha256 pair in the wallpaper casks by downloading
each URL and comparing its SHA-256 against the cask file.

Bypasses cask runtime conditionals (e.g. `if File.exist?("/usr/bin/plasmashell")`)
that hide variants from `brew bump-cask-pr` and `brew fetch`.

Usage:
    ./scripts/verify-wallpapers.py
    ./scripts/verify-wallpapers.py Casks/bluefin-wallpapers-extra.rb
"""

from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path
from urllib.request import urlopen

SCRIPT_DIR = Path(__file__).parent
CASKS_DIR = SCRIPT_DIR.parent / "Casks"
DEFAULT_GLOB = "*wallpapers*.rb"

TOKEN_RE = re.compile(r'(url|sha256)\s+"([^"]+)"')
SHA_RE = re.compile(r"[0-9a-f]{64}")
VERSION_RE = re.compile(r'version\s+"([^"]+)"')
LIVECHECK_RE = re.compile(r"livecheck\s+do\b.*?\bend\b", re.DOTALL)


def extract_pairs(cask_path: Path) -> list[tuple[str, str]]:
    content = LIVECHECK_RE.sub("", cask_path.read_text())
    version_match = VERSION_RE.search(content)
    if not version_match:
        raise ValueError(f"No version found in {cask_path}")
    version = version_match.group(1)

    tokens = [
        (kind, value)
        for kind, value in TOKEN_RE.findall(content)
        if kind == "url" or SHA_RE.fullmatch(value)
    ]

    pairs: list[tuple[str, str]] = []
    i = 0
    while i < len(tokens) - 1:
        a, b = tokens[i], tokens[i + 1]
        if {a[0], b[0]} == {"url", "sha256"}:
            url = a[1] if a[0] == "url" else b[1]
            sha = b[1] if a[0] == "url" else a[1]
            url = url.replace("#{version}", version)
            if "#{" in url:
                raise ValueError(f"Unresolved interpolation in URL: {url}")
            pairs.append((url, sha))
            i += 2
        else:
            i += 1
    return pairs


def fetch_sha256(url: str) -> str:
    h = hashlib.sha256()
    with urlopen(url) as response:
        while chunk := response.read(1 << 20):
            h.update(chunk)
    return h.hexdigest()


def verify_cask(cask_path: Path) -> list[str]:
    failures: list[str] = []
    pairs = extract_pairs(cask_path)
    print(f"=== {cask_path.name} ({len(pairs)} variants) ===")
    for url, expected in pairs:
        actual = fetch_sha256(url)
        status = "OK" if actual == expected else "MISMATCH"
        print(f"  [{status}] {url.rsplit('/', 1)[-1]}")
        if actual != expected:
            failures.append(
                f"{cask_path.name}: {url}\n    expected {expected}\n    actual   {actual}"
            )
    return failures


def main() -> int:
    if len(sys.argv) > 1:
        cask_paths = [Path(arg) for arg in sys.argv[1:]]
    else:
        cask_paths = sorted(CASKS_DIR.glob(DEFAULT_GLOB))

    failures: list[str] = []
    for cask_path in cask_paths:
        failures.extend(verify_cask(cask_path))

    print()
    if failures:
        print("FAILURES:")
        for f in failures:
            print(f"  {f}")
        return 1
    print("All checksums match.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

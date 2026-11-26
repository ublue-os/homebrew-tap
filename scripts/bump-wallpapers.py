#!/usr/bin/env python3
"""
Bump wallpaper casks with all SHA256 variants.

Usage:
    ./scripts/bump-wallpapers.py                     # bump all to latest
    ./scripts/bump-wallpapers.py bluefin-wallpapers  # bump specific cask to latest
    ./scripts/bump-wallpapers.py bluefin-wallpapers 2025-12-10  # bump to specific version
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import re
import sys
from dataclasses import dataclass, field
from enum import Enum
from functools import cache
from pathlib import Path
from typing import TYPE_CHECKING
from urllib.request import Request, urlopen

if TYPE_CHECKING:
    from typing import TypeAlias

    Release: TypeAlias = dict[str, any]
    Asset: TypeAlias = dict[str, any]

__all__ = [
    "Variant",
    "CaskConfig",
    "BumpError",
    "ReleaseNotFoundError",
    "AssetNotFoundError",
    "get_releases",
    "bump_cask",
    "bump_all",
]

logger = logging.getLogger(__name__)

SCRIPT_DIR = Path(__file__).parent
CASKS_DIR = SCRIPT_DIR.parent / "Casks"
GITHUB_API_URL = "https://api.github.com/repos/ublue-os/artwork/releases"


class BumpError(Exception):
    """Base exception for bump errors."""


class ReleaseNotFoundError(BumpError):
    """Raised when a release cannot be found."""


class AssetNotFoundError(BumpError):
    """Raised when a release asset cannot be found."""


class CaskFileNotFoundError(BumpError):
    """Raised when a cask file cannot be found."""


class Variant(Enum):
    """Wallpaper package variants."""

    MACOS = "macos"
    KDE = "kde"
    GNOME = "gnome"
    PNG = "png"


@dataclass
class CaskConfig:
    """Configuration for a wallpaper cask."""

    name: str
    release_prefix: str
    artifact_name: str
    variants: list[Variant] = field(default_factory=lambda: list(Variant))

    @property
    def cask_file(self) -> Path:
        """Path to the cask file."""
        return CASKS_DIR / f"{self.name}.rb"

    def get_tag(self, version: str) -> str:
        """Get the release tag for a version."""
        return f"{self.release_prefix}-v{version}"

    def get_asset_name(self, variant: Variant) -> str:
        """Get the asset filename for a variant."""
        return f"{self.artifact_name}-{variant.value}.tar.zstd"


# Cask configurations
CASKS = [
    CaskConfig(
        name="bluefin-wallpapers",
        release_prefix="bluefin",
        artifact_name="bluefin-wallpapers",
    ),
    CaskConfig(
        name="bluefin-wallpapers-extra",
        release_prefix="bluefin-extra",
        artifact_name="bluefin-wallpapers-extra",
    ),
    CaskConfig(
        name="framework-wallpapers",
        release_prefix="framework",
        artifact_name="framework-wallpapers",
    ),
]

CASK_BY_NAME = {cask.name: cask for cask in CASKS}

@cache
def get_releases() -> list[Release]:
    """Fetch all releases from GitHub API (cached)."""
    logger.debug("Fetching releases from %s", GITHUB_API_URL)
    headers = {"Accept": "application/vnd.github+json"}
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        headers["Authorization"] = "Bearer " + token
    request = Request(GITHUB_API_URL, headers=headers)
    with urlopen(request) as response:
        return json.loads(response.read().decode())


def find_release(releases: list[Release], tag_prefix: str, version: str | None = None) -> Release:
    """Find a release by tag prefix and optional version."""
    for release in releases:
        tag = release["tag_name"]
        if version:
            if tag == f"{tag_prefix}-v{version}":
                return release
        elif tag.startswith(f"{tag_prefix}-v"):
            return release

    version_str = version or "latest"
    raise ReleaseNotFoundError(f"No release found for {tag_prefix} ({version_str})")


def get_asset_sha256(release: Release, asset_name: str) -> str:
    """Extract SHA256 from release asset's digest field."""
    for asset in release.get("assets", []):
        if asset["name"] == asset_name:
            if digest := asset.get("digest", ""):
                if digest.startswith("sha256:"):
                    return digest[7:]
            raise AssetNotFoundError(f"No digest found for asset: {asset_name}")

    raise AssetNotFoundError(f"Asset not found: {asset_name}")


SHA256_LINE_RE = re.compile(r'^\s*sha256\s+"[^"]+"')
URL_LINE_RE = re.compile(r'^\s*url\s+"')
BLOCK_BOUNDARY_RE = re.compile(r"^\s*(end\b|else\b|elsif\b|if\b|on_\w+\s+do\b)")


def find_sha256_for_url(lines: list[str], url_index: int) -> int | None:
    """Find the sha256 line paired with the url at url_index.

    The pair must sit in the same block (between the same if/elsif/else/
    on_* ... end boundaries) and may come before or after the url.
    """
    for step in (1, -1):
        i = url_index + step
        while 0 <= i < len(lines):
            line = lines[i]
            if BLOCK_BOUNDARY_RE.match(line) or URL_LINE_RE.match(line):
                break
            if SHA256_LINE_RE.match(line):
                return i
            i += step
    return None


def update_sha256_for_url(content: str, url_pattern: str, new_sha256: str) -> str:
    """Update the sha256 paired with the url containing url_pattern."""
    lines = content.split("\n")
    url_indices = [
        i for i, line in enumerate(lines)
        if URL_LINE_RE.match(line) and url_pattern in line
    ]
    if not url_indices:
        raise AssetNotFoundError(f"No url line for {url_pattern} in cask")

    for url_index in url_indices:
        sha_index = find_sha256_for_url(lines, url_index)
        if sha_index is None:
            raise BumpError(f"No sha256 paired with url for {url_pattern}")
        lines[sha_index] = re.sub(
            r'sha256\s+"[^"]+"', f'sha256 "{new_sha256}"', lines[sha_index]
        )

    return "\n".join(lines)


def update_version(content: str, new_version: str) -> str:
    """Update the version in cask content."""
    return re.sub(r'(version\s+")[^"]+(")', rf"\g<1>{new_version}\g<2>", content)


def update_single_sha256(content: str, new_sha256: str) -> str:
    """Update a single sha256 value (for single-variant casks)."""
    return re.sub(r'(sha256\s+")[^"]+(")', rf"\g<1>{new_sha256}\g<2>", content)


def get_current_version(content: str) -> str:
    """Extract current version from cask content."""
    if match := re.search(r'version\s+"([^"]+)"', content):
        return match.group(1)
    return "unknown"


def bump_cask(config: CaskConfig, version: str | None = None) -> None:
    """Bump a wallpaper cask to a specific or latest version."""
    if not config.cask_file.exists():
        raise CaskFileNotFoundError(f"Cask file not found: {config.cask_file}")

    releases = get_releases()
    release = find_release(releases, config.release_prefix, version)
    target_version = release["tag_name"].replace(f"{config.release_prefix}-v", "")

    logger.info("Bumping %s to %s", config.name, target_version)

    content = config.cask_file.read_text()
    current_version = get_current_version(content)
    logger.info("  Current version: %s", current_version)

    content = update_version(content, target_version)

    if config.variants:
        for variant in config.variants:
            asset_name = config.get_asset_name(variant)
            try:
                sha256 = get_asset_sha256(release, asset_name)
                logger.info("  %s: %s", variant.value, sha256)
                content = update_sha256_for_url(content, asset_name, sha256)
            except AssetNotFoundError:
                logger.warning("  %s: not found, skipping", variant.value)
    else:
        asset_name = f"{config.artifact_name}.tar.zstd"
        sha256 = get_asset_sha256(release, asset_name)
        logger.info("  SHA256: %s", sha256)
        content = update_single_sha256(content, sha256)

    config.cask_file.write_text(content)
    logger.info("  Done!")


def bump_all(version: str | None = None) -> bool:
    """Bump all wallpaper casks. Returns True if all succeeded."""
    success = True

    for config in CASKS:
        try:
            bump_cask(config, version)
        except BumpError as e:
            logger.error("Failed to bump %s: %s", config.name, e)
            success = False

    return success


def setup_logging(verbose: bool = False) -> None:
    """Configure logging."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(message)s",
        handlers=[logging.StreamHandler()],
    )


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Bump wallpaper casks with all SHA256 variants"
    )
    parser.add_argument(
        "cask",
        nargs="?",
        choices=list(CASK_BY_NAME.keys()),
        metavar="CASK",
        help="Specific cask to bump (default: all)",
    )
    parser.add_argument(
        "version",
        nargs="?",
        help="Specific version (default: latest)",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose output",
    )
    args = parser.parse_args()

    setup_logging(args.verbose)

    logger.info("=== Wallpaper Cask Bumper ===")
    logger.info("")

    try:
        if args.cask:
            config = CASK_BY_NAME[args.cask]
            bump_cask(config, args.version)
            success = True
        else:
            logger.info("Fetching releases from GitHub API...")
            logger.info("")
            success = bump_all(args.version)

        logger.info("")
        logger.info("=== Complete ===")
        return 0 if success else 1

    except BumpError as e:
        logger.error("Error: %s", e)
        return 1


if __name__ == "__main__":
    sys.exit(main())

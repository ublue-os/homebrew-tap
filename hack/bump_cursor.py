#!/usr/bin/env python3
"""
Cursor Homebrew Cask Version Bumper
Inspired by the AUR cursor-bin updater
"""

import sys
import json
import hashlib
import requests
import re
import os

DEBUG = os.environ.get("DEBUG", "false").lower() == "true"


def debug_print(*args, **kwargs):
    if DEBUG:
        print(*args, **kwargs, file=sys.stderr)


def get_latest_cursor_info():
    """Get the latest commit hash and version from Cursor's update API."""
    # Try both architectures
    architectures = {
        "x64": "https://api2.cursor.sh/updates/api/update/linux-x64/cursor/1.0.0/hash/stable",
        "arm64": "https://api2.cursor.sh/updates/api/update/linux-arm64/cursor/1.0.0/hash/stable",
    }
    
    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
        " (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
        "Accept": "application/json",
        "Cache-Control": "no-cache",
    }

    results = {}
    
    for arch, api_url in architectures.items():
        debug_print(f"Checking {arch} version...")
        try:
            response = requests.get(api_url, headers=headers, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            version = data["version"]
            update_url = data["url"]
            
            # Parse commitSha from the update_url
            commit_match = re.search(r'/production/([a-f0-9]{40})/', update_url)
            if not commit_match:
                print(f"Warning: Failed to extract commit from {arch} update URL", file=sys.stderr)
                continue
                
            commit = commit_match.group(1)
            
            # Construct AppImage download URL
            download_url = f"https://downloader.cursor.sh/linux/appImage/{arch}"
            
            debug_print(f"{arch}: version={version}, commit={commit}")
            results[arch] = {
                "version": version,
                "commit": commit,
                "download_url": download_url
            }
            
        except Exception as e:
            print(f"Warning: Failed to get {arch} info: {e}", file=sys.stderr)
            continue
    
    if not results:
        return None
    
    # Verify versions match across architectures
    versions = set(r["version"] for r in results.values())
    if len(versions) > 1:
        print(f"Warning: Version mismatch across architectures: {versions}", file=sys.stderr)
    
    return results


def calculate_sha256(url):
    """Download file and calculate its SHA256."""
    debug_print(f"Downloading {url} to calculate SHA256...")
    
    try:
        response = requests.get(url, stream=True, timeout=300)
        response.raise_for_status()
        
        sha256_hash = hashlib.sha256()
        chunk_count = 0
        
        for chunk in response.iter_content(chunk_size=8192):
            sha256_hash.update(chunk)
            chunk_count += 1
            if chunk_count % 1000 == 0:
                debug_print(f"  Processed {chunk_count} chunks...")
        
        result = sha256_hash.hexdigest()
        debug_print(f"  SHA256: {result}")
        return result
        
    except Exception as e:
        print(f"Error calculating SHA256 for {url}: {e}", file=sys.stderr)
        raise


def get_current_cask_version(cask_path):
    """Extract current version from the cask file."""
    with open(cask_path, 'r') as f:
        content = f.read()
    
    version_match = re.search(r'version "([^"]+)"', content)
    if version_match:
        return version_match.group(1)
    return None


def update_cask_file(cask_path, info):
    """Update the cask file with new version, commit SHA, and checksums."""
    with open(cask_path, 'r') as f:
        lines = f.readlines()
    
    version = info["x64"]["version"]
    commit = info["x64"]["commit"]
    
    # Construct full download URLs with commit hash
    x64_url = f"https://downloads.cursor.com/production/{commit}/linux/x64/Cursor-{version}-x86_64.AppImage"
    arm64_url = f"https://downloads.cursor.com/production/{commit}/linux/arm64/Cursor-{version}-aarch64.AppImage"
    
    # Calculate SHA256 for both architectures
    print("Calculating SHA256 checksums (this may take a few minutes)...")
    sha256_x64 = calculate_sha256(x64_url)
    
    sha256_arm64 = "SKIP"  # Default if arm64 not available
    if "arm64" in info:
        try:
            sha256_arm64 = calculate_sha256(arm64_url)
        except Exception as e:
            print(f"Warning: Could not calculate arm64 checksum: {e}", file=sys.stderr)
    
    updated_lines = []
    in_sha_block = False
    
    for i, line in enumerate(lines):
        if line.strip().startswith('version "'):
            updated_lines.append(f'  version "{version}"\n')
        elif line.strip().startswith('commit_sha "'):
            updated_lines.append(f'  commit_sha "{commit}"\n')
        elif line.strip().startswith('sha256 arm64_linux:'):
            # Start of sha256 block
            updated_lines.append(f'  sha256 arm64_linux:  "{sha256_arm64}",\n')
            in_sha_block = True
        elif in_sha_block and 'x86_64_linux:' in line:
            # Second line of sha256 block
            updated_lines.append(f'         x86_64_linux: "{sha256_x64}"\n')
            in_sha_block = False
        else:
            updated_lines.append(line)
    
    with open(cask_path, 'w') as f:
        f.writelines(updated_lines)
    
    print(f"Updated {cask_path} to version {version}")
    print(f"  Commit SHA:   {commit}")
    print(f"  x64 SHA256:   {sha256_x64}")
    print(f"  arm64 SHA256: {sha256_arm64}")


def main():
    cask_path = os.path.join(
        os.path.dirname(__file__), 
        "..", 
        "Casks", 
        "cursor-linux.rb"
    )
    
    if not os.path.exists(cask_path):
        print(f"Error: Cask file not found at {cask_path}", file=sys.stderr)
        sys.exit(1)
    
    print("Fetching latest Cursor version info...")
    info = get_latest_cursor_info()
    
    if not info or "x64" not in info:
        print("Error: Could not fetch Cursor version info", file=sys.stderr)
        sys.exit(1)
    
    current_version = get_current_cask_version(cask_path)
    new_version = info["x64"]["version"]
    
    print(f"Current version: {current_version}")
    print(f"Latest version:  {new_version}")
    
    if current_version == new_version:
        response = input("Versions match. Update anyway? [y/N] ")
        if response.lower() != 'y':
            print("Aborted.")
            sys.exit(0)
    
    update_cask_file(cask_path, info)
    print("\nDone! Don't forget to:")
    print("  1. Test the cask: brew install --cask --dry-run hanthor/tap/cursor-linux")
    print("  2. Commit the changes: git add Casks/cursor-linux.rb && git commit -m 'Bump cursor-linux to " + new_version + "'")


if __name__ == "__main__":
    main()

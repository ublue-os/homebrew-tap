#!/usr/bin/env ruby
# frozen_string_literal: true

require "open-uri"
require "digest"
require "json"

CASKS = [
  {
    name:      "bluefin-wallpapers",
    repo:      "ublue-os/artwork",
    regex:     /bluefin-v?(\d{4}-\d{2}-\d{2})/,
    artifacts: {
      kde:   "bluefin-wallpapers-kde.tar.zstd",
      gnome: "bluefin-wallpapers-gnome.tar.zstd",
      png:   "bluefin-wallpapers-png.tar.zstd",
    },
  },
  {
    name:      "bluefin-wallpapers-extra",
    repo:      "ublue-os/artwork",
    regex:     /bluefin-extra-v?(\d{4}-\d{2}-\d{2})/,
    artifacts: {
      kde:   "bluefin-wallpapers-extra-kde.tar.zstd",
      gnome: "bluefin-wallpapers-extra-gnome.tar.zstd",
      png:   "bluefin-wallpapers-extra-png.tar.zstd",
    },
  },
  {
    name:      "framework-wallpapers",
    repo:      "ublue-os/artwork",
    regex:     /framework-v?(\d{4}-\d{2}-\d{2})/,
    artifacts: {
      kde:   "framework-wallpapers-kde.tar.zstd",
      gnome: "framework-wallpapers-gnome.tar.zstd",
      png:   "framework-wallpapers-png.tar.zstd",
    },
  },
].freeze

def fetch_latest_version(repo, regex)
  # GitHub API to get releases
  api_url = "https://api.github.com/repos/#{repo}/releases"
  headers = { "Accept" => "application/vnd.github.v3+json" }
  headers["Authorization"] = "token #{ENV.fetch('HOMEBREW_GITHUB_API_TOKEN', nil)}" if ENV['HOMEBREW_GITHUB_API_TOKEN']

  begin
    URI.open(api_url, headers) do |f|
      releases = JSON.parse(f.read)
      releases.each do |release|
        match = release["tag_name"].match(regex)
        return match[1], release["tag_name"] if match
      end
    end
  rescue => e
    puts "Error fetching releases for #{repo}: #{e.message}"
    return nil, nil
  end
  [nil, nil]
end

def calculate_sha(url)
  puts "  Downloading #{url}..."
  begin
    URI.open(url) do |f|
      Digest::SHA256.hexdigest(f.read)
    end
  rescue => e
    puts "  Failed to download #{url}: #{e.message}"
    nil
  end
end

CASKS.each do |cask_info|
  puts "Checking #{cask_info[:name]}..."

  new_version, tag_name = fetch_latest_version(cask_info[:repo], cask_info[:regex])

  unless new_version
    puts "  Could not find latest version matching regex."
    next
  end

  cask_path = File.join(__dir__, "../../Casks/#{cask_info[:name]}.rb")
  content = File.read(cask_path)

  current_version_match = content.match(/version "([^"]+)"/)
  current_version = current_version_match ? current_version_match[1] : nil

  if current_version == new_version
    puts "  Already up to date (Version #{current_version})"
    next
  end

  puts "  New version found: #{new_version} (Current: #{current_version})"

  # Collect SHAs
  new_shas = {}
  cask_info[:artifacts].each do |variant, filename|
    # Construct URL based on the typical pattern found in these casks
    # Pattern: https://github.com/ublue-os/artwork/releases/download/#{tag_name}/#{filename}
    # Note: filename in struct is just the basename.
    # But wait, looking at bluefin-wallpapers.rb:
    # url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-kde.tar.zstd"
    # So we can construct it using the tag_name we found.

    url = "https://github.com/#{cask_info[:repo]}/releases/download/#{tag_name}/#{filename}"
    sha = calculate_sha(url)
    if sha
      new_shas[variant] = sha
    else
      puts "  Skipping update due to missing artifact: #{filename}"
      new_shas = nil
      break
    end
  end

  next unless new_shas

  # Update content
  new_content = content.sub(/version "#{current_version}"/, "version \"#{new_version}\"")

  # Update SHAs. We assume the order: KDE -> GNOME -> PNG or rely on unique URL substrings.
  # The safest way is to regex match the block containing the specific filename or url pattern.
  # Regex to match: url ".*?-kde.tar.zstd"\n\s+sha256 "OLD_SHA"

  cask_info[:artifacts].each do |variant, filename|
    # Build a regex that matches the url line (ignoring the version part in it) and capturing the sha line
    # We use part of the filename that is unique, e.g., "kde.tar.zstd"
    unique_part = filename.sub(/bluefin-wallpapers(-extra)?-|framework-wallpapers-/, "")
    # Actually, simpler: match the filename extension part which is consistent in the URL line
    # The URL line in cask uses interpolation, so literal match won't work easily.
    # But filtering by the file suffix (kde.tar.zstd) works.

    # suffix is like "kde.tar.zstd" or "gnome.tar.zstd"

    # We expect `url "...#{suffix}"` followed eventually by `sha256 "..."`
    # Warning: simple multiline regex might be tricky if there are intervening lines.
    # In these files, sha256 follows url immediately or closely.

    new_sha = new_shas[variant]

    # We look for a line containing the artifact filename pattern, then replace the NEXT sha256 occurrence.
    # OR, we replace based on context.

    # Let's try to match the block:
    # url "....-kde.tar.zstd"\n    sha256 "..."
    # Since the URL line changes (version), we can't search for the exact new URL yet,
    # but we can search for the interpolation string or just the end of the string.

    # The artifact map has the literal filename logic.
    # "bluefin-wallpapers-kde.tar.zstd" -> in cask it is "bluefin-wallpapers-kde.tar.zstd"

    # Regex:
    # url ".*?-#{variant}\.tar\.zstd"\n\s+sha256 "([a-f0-9]+)"
    # Note: `variant` symbol needs mapping to string if needed.
    # effectively: kde -> kde, gnome -> gnome, png -> png

    # Special handling for "bluefin-wallpapers-extra" which has "-night|-day" replacements logic in code but URL is simple.

    variant_str = variant.to_s

    if new_content.sub!(/(url ".*?#{variant_str}\.tar\.zstd"\n\s+sha256 ")([a-f0-9]+)(")/m, "\\1#{new_sha}\\3")
      puts "  Updated #{variant} SHA."
    else
      puts "  WARNING: Could not find sha256 pattern for #{variant}."
    end
  end

  File.write(cask_path, new_content)
  puts "  Updated #{cask_info[:name]} to #{new_version}"
end

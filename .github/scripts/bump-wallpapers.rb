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


  cask_info[:artifacts].each do |variant, filename|
    unique_part = filename.sub(/bluefin-wallpapers(-extra)?-|framework-wallpapers-/, "")

    new_sha = new_shas[variant]
  
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

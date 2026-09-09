cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "1.1.28,5576113066475520"
  sha256 arm:          "789420d2937393498eb158c4af8321d78c387e31c861db0c79627879509aa8a8",
         intel:        "074ff4f732a750ad727aeed5fc82ed34b1fb72fda2a6ceba6c8e652ffd0a94b0",
         arm64_linux:  "789420d2937393498eb158c4af8321d78c387e31c861db0c79627879509aa8a8",
         x86_64_linux: "074ff4f732a750ad727aeed5fc82ed34b1fb72fda2a6ceba6c8e652ffd0a94b0"

  url "https://storage.googleapis.com/antigravity-public/antigravity-cli/#{version.csv.first}-#{version.csv.second}/linux-#{arch}/cli_linux_#{(arch == "arm") ? "arm64" : "x64"}.tar.gz"
  name "Google Antigravity CLI"
  desc "Terminal interface for Antigravity agents"
  homepage "https://antigravity.google/product/antigravity-cli"

  livecheck do
    url "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_#{(arch == "arm") ? "arm64" : "amd64"}.json"
    regex(%r{/antigravity-cli/([^/]+)/}i)
    strategy :json do |json, regex|
      match = json["url"]&.match(regex)
      next if match.blank?

      match[1]&.tr("-", ",").to_s
    end
  end

  binary "agy.wrapper.sh", target: "agy"

  preflight_steps do
    write_file "agy.wrapper.sh", <<~EOS
      #!/bin/sh
      if [ "$1" = "update" ]; then
        echo "Antigravity CLI is managed by Homebrew. Use 'brew upgrade --cask antigravity-cli-linux' instead." >&2
        exit 1
      fi

      exec "{{staged_path}}/antigravity" "$@"
    EOS
    set_permissions "agy.wrapper.sh", "0755"
  end

  zap trash: "~/.gemini/antigravity-cli"
end

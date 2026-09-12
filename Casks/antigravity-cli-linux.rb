cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "1.2.2,6061403484848128"
  sha256 arm:          "00fc5cb50cd714b81cdf1298fcc90e63a59e3e564a4f8076454ab8457d36e6eb",
         intel:        "2cfa5c9a4a1edd96db6d4058f34970be60d3bcacda866e2bdce6aefb2451b48e",
         arm64_linux:  "00fc5cb50cd714b81cdf1298fcc90e63a59e3e564a4f8076454ab8457d36e6eb",
         x86_64_linux: "2cfa5c9a4a1edd96db6d4058f34970be60d3bcacda866e2bdce6aefb2451b48e"

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

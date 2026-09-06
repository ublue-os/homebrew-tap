cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "1.1.27,5211191891591168"
  sha256 arm:          "97fc9fe5a6067406cd02cbe4ae6e362c9623a24d33bec486911246c17ceb6a94",
         intel:        "f874d4f6b8a73c2df660f580f25fb656fcb6e64adbfd746e6692e837fd9a20be",
         arm64_linux:  "97fc9fe5a6067406cd02cbe4ae6e362c9623a24d33bec486911246c17ceb6a94",
         x86_64_linux: "f874d4f6b8a73c2df660f580f25fb656fcb6e64adbfd746e6692e837fd9a20be"

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

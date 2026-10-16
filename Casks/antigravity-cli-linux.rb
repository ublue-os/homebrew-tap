cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "1.3.6,5068262057312256"
  sha256 arm:          "0e11472f376e2943c6f812280dea49b204acc3be15794c6604a46972c5995b12",
         intel:        "e88ed835cbc4af504f64dfe20175f5572dc2a425dbfa2fcf55c0358bb444d80c",
         arm64_linux:  "0e11472f376e2943c6f812280dea49b204acc3be15794c6604a46972c5995b12",
         x86_64_linux: "e88ed835cbc4af504f64dfe20175f5572dc2a425dbfa2fcf55c0358bb444d80c"

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

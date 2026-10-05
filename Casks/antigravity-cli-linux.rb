cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "1.2.17,6683332533157888"
  sha256 arm:          "4a1af1bb91352b72f40fce373a028023bf0e47f5fceb3dfa48249816c0f0caec",
         intel:        "b0ed8a7c375b5af3af973f08a601e41aebb38bac7e80b922ab54d973a4275493",
         arm64_linux:  "4a1af1bb91352b72f40fce373a028023bf0e47f5fceb3dfa48249816c0f0caec",
         x86_64_linux: "b0ed8a7c375b5af3af973f08a601e41aebb38bac7e80b922ab54d973a4275493"

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

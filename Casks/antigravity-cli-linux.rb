cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "1.1.7,5951805767680000"
  sha256 arm:          "0d6d488851745e80e69b8935d063e742945811b47111994b1a6dbd27df3010d5",
         intel:        "946cd06258d0ede72d0311550c914315798821f6a397f53ac760919826a19af4",
         arm64_linux:  "0d6d488851745e80e69b8935d063e742945811b47111994b1a6dbd27df3010d5",
         x86_64_linux: "946cd06258d0ede72d0311550c914315798821f6a397f53ac760919826a19af4"

  url "https://storage.googleapis.com/antigravity-public/antigravity-cli/#{version.csv.first}-#{version.csv.second}/linux-#{arch}/cli_linux_#{(arch == "arm") ? "arm64" : "x64"}.tar.gz",
      verified: "storage.googleapis.com/antigravity-public/antigravity-cli/"
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

  preflight do
    File.write("#{staged_path}/agy.wrapper.sh", <<~EOS)
      #!/bin/sh
      if [ "$1" = "update" ]; then
        echo "Antigravity CLI is managed by Homebrew. Use 'brew upgrade --cask antigravity-cli-linux' instead." >&2
        exit 1
      fi

      exec "#{staged_path}/antigravity" "$@"
    EOS
    FileUtils.chmod 0755, "#{staged_path}/agy.wrapper.sh"
  end

  zap trash: "~/.gemini/antigravity-cli"
end

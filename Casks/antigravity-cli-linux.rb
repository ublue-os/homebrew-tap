cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "1.1.23,6260551186251776"
  sha256 arm:          "cbf2299514468eb31b9ccce7b89a0a011dc6497894c199c06f6b771cc9848a67",
         intel:        "379693509ca4d68d74f75def6c95996739aa6c1dc38b120c399035c108f1a39a",
         arm64_linux:  "cbf2299514468eb31b9ccce7b89a0a011dc6497894c199c06f6b771cc9848a67",
         x86_64_linux: "379693509ca4d68d74f75def6c95996739aa6c1dc38b120c399035c108f1a39a"

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

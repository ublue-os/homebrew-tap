cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "1.1.15,5350383476932608"
  sha256 arm:          "5be066db6673faaec233e8cdb3f494aea3f30d8bf21a5fe0d6cf19451d83b7c6",
         intel:        "d0b1d6f3678a061915caebc431930e240b863bf4059369c08c6ffceb24e66b5f",
         arm64_linux:  "5be066db6673faaec233e8cdb3f494aea3f30d8bf21a5fe0d6cf19451d83b7c6",
         x86_64_linux: "d0b1d6f3678a061915caebc431930e240b863bf4059369c08c6ffceb24e66b5f"

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

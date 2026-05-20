cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "1.0.0,5288553236791296"

  on_linux do
    sha256 arm64_linux:  "f4dc7c96c1836b00768d8a6ec6eacc7851f3424bd6f4ebe4d8b848a652072a85",
           x86_64_linux: "70096340574fafc4a06c4d3c8057314e22d475ce1c820d0ad51ff07fb7e99eb6"
  end

  url "https://storage.googleapis.com/antigravity-public/antigravity-cli/#{version.csv.first}-#{version.csv.second}/linux-#{arch}/cli_linux_#{arch == "arm" ? "arm64" : "x64"}.tar.gz",
      verified: "storage.googleapis.com/antigravity-public/antigravity-cli/"
  name "Antigravity CLI"
  desc "AI Coding Agent CLI (successor to Gemini CLI)"
  homepage "https://antigravity.google/cli"

  livecheck do
    url "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_amd64.json"
    strategy :json do |json|
      version = json["version"]
      match = json["url"]&.match(%r{/([\d.]+-(\d+))/})
      next if match.blank?

      "#{version},#{match[2]}"
    end
  end

  binary "antigravity"
  binary "antigravity", target: "agy"

  zap trash: [
    "~/.gemini/antigravity-cli",
    "~/.antigravity-cli",
  ]

  caveats <<~EOS
    Antigravity CLI is the new agent-first development tool from Google, replacing Gemini CLI.
    It is recommended to use this alongside the Antigravity IDE (antigravity-linux).
  EOS
end

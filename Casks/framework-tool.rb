cask "framework-tool" do
  version "0.6.5"
  sha256 "0b223b09dbf0c05cfd18878e0be113294e35ea32120b93de1888a26cf6595cfc"

  url "https://github.com/FrameworkComputer/framework-system/releases/download/v#{version}/framework_tool"
  name "Framework System Tool"
  desc "System tool for Framework laptop hardware management"
  homepage "https://github.com/FrameworkComputer/framework-system"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "framework_tool", target: "framework_tool"
end

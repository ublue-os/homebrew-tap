cask "framework-tool" do
  version "0.6.1"
  sha256 "51665b79752c6bb7a41fc41436eca90db83ebdb51e411fecc2a778729e634207"

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

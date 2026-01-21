cask "framework-tool" do
  version "0.5.0"
  sha256 "920283caef7466e224d52be7b90eba1ca616c391f23ad581e874ff09f81f11bc"

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

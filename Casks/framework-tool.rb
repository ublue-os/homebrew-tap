cask "framework-tool" do
  version "0.6.4"
  sha256 "83b04df1fbd950c88bb569e91503cbf7a616663ad7ff6cbcb0e99a67509a8584"

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

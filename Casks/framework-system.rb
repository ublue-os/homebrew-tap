cask "framework-system" do
  version "0.4.5"
  sha256 "e94af70b2a287577c3d7e26e92e1a3910bd27b725543ac5763b7cd348d8fb57d"

  url "https://github.com/FrameworkComputer/framework-system/releases/download/v#{version}/framework_tool"
  name "Framework System Tool"
  desc "System tool for Framework laptop hardware management"
  homepage "https://github.com/FrameworkComputer/framework-system"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "framework_tool", target: "framework-system"
end
cask "framework-tool" do
  version "0.6.3"
  sha256 "cb8bc4c798baaf5ab32040424621efb02e0d2ef348bde71d0b3a51d693676b3d"

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

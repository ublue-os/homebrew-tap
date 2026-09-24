cask "framework-tool" do
  version "0.6.6"
  sha256 "ebc2f3ca300dac6f484c02d058833372ff8dd3c23f2a74b63c774f8dc2f86171"

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

cask "framework-tool" do
  version "0.6.2"
  sha256 "2c03a7843ab1ef3625e22b9066c59e6bb42be7e5ef5c4ab18e0cde6598fe6f0c"

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

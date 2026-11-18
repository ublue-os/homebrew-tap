cask "framework-tool" do
  version "0.6.7"
  sha256 "a58872c6a2c54e79cd3e95bc4a05c8a752437620a79cd19829d138f44c1f482d"

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

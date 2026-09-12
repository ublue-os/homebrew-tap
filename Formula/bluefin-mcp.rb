class BluefinMcp < Formula
  desc "MCP server providing AI context for Project Bluefin systems"
  homepage "https://github.com/projectbluefin/bluefin-mcp"
  url "https://github.com/projectbluefin/bluefin-mcp/archive/refs/tags/v0.1.0.tar.gz"
  version "0.1.0"
  sha256 "ba5a15326b2e397d4ab49bf342b1c12caa304ec5062782658658451512e6e2ad"
  license "Apache-2.0"

  head "https://github.com/projectbluefin/bluefin-mcp.git", branch: "main"

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/bluefin-mcp"
  end

  def caveats
    <<~EOS
      Add bluefin-mcp to your MCP client configuration.
      Use the absolute path to the binary:

        #{opt_bin}/bluefin-mcp

      Example MCP config entry:
        {
          "mcpServers": {
            "bluefin": {
              "command": "#{opt_bin}/bluefin-mcp"
            }
          }
        }

      For full coverage, also install linux-mcp-server:
        https://github.com/rhel-lightspeed/linux-mcp-server
    EOS
  end

  test do
    assert_match "bluefin-mcp", shell_output("#{bin}/bluefin-mcp --version 2>&1")
  end
end

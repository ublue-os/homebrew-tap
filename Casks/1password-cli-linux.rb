cask "1password-cli-linux" do
  arch arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "2.42.0"
  sha256 arm:          "e56c379fabafb393ce699258e484694abe464870fb41f35ce1b5c3f17868ba61",
         intel:        "261fe3844a43e7e83a3d85e8a9f36411729436a1d3add1dc7dd46cbbceebe9e5",
         arm64_linux:  "e56c379fabafb393ce699258e484694abe464870fb41f35ce1b5c3f17868ba61",
         x86_64_linux: "261fe3844a43e7e83a3d85e8a9f36411729436a1d3add1dc7dd46cbbceebe9e5"

  url "https://cache.agilebits.com/dist/1P/op2/pkg/v#{version}/op_linux_#{arch}_v#{version}.zip"
  name "1Password CLI"
  desc "Command-line interface for 1Password"
  homepage "https://developer.1password.com/docs/cli"

  livecheck do
    url "https://app-updates.agilebits.com/check/1/0/CLI2/en/0/N"
    strategy :json do |json|
      json["version"]
    end
  end

  conflicts_with cask: "1password-cli"

  binary "op"
  generate_completions_from_executable "op", "completion"

  postflight_steps do
    # Desktop integration requires root:onepassword-cli ownership and setgid.
    # https://developer.1password.com/docs/cli/app-integration/
    run "/bin/sh", args: ["-eu", "-c", "getent group onepassword-cli >/dev/null || groupadd onepassword-cli"],
                   sudo: true
    set_ownership "op", user: "root", group: "onepassword-cli", recursive: false
    run "/bin/chmod", args: ["2755", "{{staged_path}}/op"], sudo: true
  end

  uninstall_preflight_steps do
    # Return ownership to the installing user before Homebrew removes the binary.
    run "/bin/chown", args: ["{{user}}:", "{{staged_path}}/op"], sudo: true
  end

  zap trash: "~/.config/op"
end

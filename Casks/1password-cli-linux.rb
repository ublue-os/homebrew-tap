cask "1password-cli-linux" do
  arch arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "2.41.0"
  sha256 arm:          "bc4ac99201909f96f67e7a89601dbf5388f991aca53120db6fc3f1666dff706b",
         intel:        "498bbaa154f0d90749325a14e04488fcd84930a426ae92ebf421d2a7d793a80a",
         arm64_linux:  "bc4ac99201909f96f67e7a89601dbf5388f991aca53120db6fc3f1666dff706b",
         x86_64_linux: "498bbaa154f0d90749325a14e04488fcd84930a426ae92ebf421d2a7d793a80a"

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

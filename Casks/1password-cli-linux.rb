cask "1password-cli-linux" do
  arch arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "2.40.0"
  sha256 arm:          "0e8ac99ee93d661aa725dc24a5ef8bf344741d224064a5dfb469dc689faec86a",
         intel:        "74277219e8da60958c00f9aee9d2023225e98fdda8bfd2156a5d9e85e0edaab3",
         arm64_linux:  "0e8ac99ee93d661aa725dc24a5ef8bf344741d224064a5dfb469dc689faec86a",
         x86_64_linux: "74277219e8da60958c00f9aee9d2023225e98fdda8bfd2156a5d9e85e0edaab3"

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

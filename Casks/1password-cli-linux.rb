cask "1password-cli-linux" do
  arch arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "2.41.1"
  sha256 arm:          "89abd60c17d5c614066c20e6abed816449eb018c5e0679ed63d57071c7bee85e",
         intel:        "e52476700cba9202ac7469bdfb2648ecdbf3438ac85822010f77230139e74966",
         arm64_linux:  "89abd60c17d5c614066c20e6abed816449eb018c5e0679ed63d57071c7bee85e",
         x86_64_linux: "e52476700cba9202ac7469bdfb2648ecdbf3438ac85822010f77230139e74966"

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

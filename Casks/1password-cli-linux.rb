cask "1password-cli-linux" do
  arch arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "2.39.0"
  sha256 arm:          "829baeff1c07e055cfa132031b1d9f2282ccdf5076258e482caf2fda70aea5d0",
         intel:        "6fba7f376b6c6dec49f41b06408930a43ad064cce103c6a2ce5b3d0413a86434",
         arm64_linux:  "829baeff1c07e055cfa132031b1d9f2282ccdf5076258e482caf2fda70aea5d0",
         x86_64_linux: "6fba7f376b6c6dec49f41b06408930a43ad064cce103c6a2ce5b3d0413a86434"

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

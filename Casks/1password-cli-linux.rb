cask "1password-cli-linux" do
  arch intel: "amd64", arm: "arm64"
  os linux: "linux"

  version "2.35.0"
  sha256 arm:          "28153b3e1b379cc117a2b8478fc29c73e4a391d0a9b7876c360d305e98390a78",
         intel:        "4457ade59850b852c64c77164235b34dd0b984ef7826eb0ccd32f1fd78a2ceb7",
         arm64_linux:  "28153b3e1b379cc117a2b8478fc29c73e4a391d0a9b7876c360d305e98390a78",
         x86_64_linux: "4457ade59850b852c64c77164235b34dd0b984ef7826eb0ccd32f1fd78a2ceb7"

  url "https://cache.agilebits.com/dist/1P/op2/pkg/v#{version}/op_linux_#{arch}_v#{version}.zip",
      verified: "cache.agilebits.com/dist/1P/op2/pkg/"
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

  postflight do
    # For the 1Password desktop app integration to trust the CLI, the op
    # binary must be owned by root:onepassword-cli with the setgid bit set.
    # The deb/rpm packages set this up in their post-install scripts; since
    # this cask installs from the zip, it has to do the same. Running this
    # in postflight also re-applies the permissions on every upgrade.
    # https://developer.1password.com/docs/cli/app-integration/
    system <<~EOS
      #!/bin/bash
      if [ ! "$(getent group onepassword-cli)" ]; then
        echo "Creating group 'onepassword-cli' for the 1Password desktop app integration, you may be prompted for your password."
        sudo groupadd onepassword-cli
      fi
    EOS
    set_ownership("#{staged_path}/op", user: "root", group: "onepassword-cli")
    # can't use set_permissions here because we no longer own the file and brew tries to run chmod without sudo
    system "sudo", "chmod", "2755", "#{File.expand_path(staged_path)}/op"
  end

  uninstall_preflight do
    # re-take ownership of the binary so brew can remove it without sudo
    system "sudo", "chown", "#{ENV.fetch("USER", nil)}:#{ENV.fetch("USER", nil)}",
           "#{File.expand_path(staged_path)}/op"
  end

  zap trash: "~/.config/op"
end

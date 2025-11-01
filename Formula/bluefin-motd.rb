class BluefinMotd < Formula
  desc "Bluefin message of the day (MOTD) and welcome banner"
  homepage "https://github.com/ublue-os/packages"
  url "https://github.com/ublue-os/packages/archive/refs/tags/homebrew-2025-10-28-01-29-41.tar.gz"
  version "0.2.1"
  sha256 "2de1cf76b2f76f90a7ef5a93b11e5cf1a24edbffc32f8db72849e75e0b61b92e"
  license "CC-BY-SA"

  def install
    # Create MOTD configuration directory
    (libexec / "motd").mkpath

    # Install MOTD banner script
    motd_content = <<~EOS
      #!/bin/sh
      # Bluefin MOTD Banner

      # Terminal color codes
      BLUE="\\033[0;34m"
      LIGHT_BLUE="\\033[1;34m"
      RESET="\\033[0m"

      # Check if we're on Bluefin
      if grep -q "bluefin" /etc/os-release 2>/dev/null; then
        echo "${LIGHT_BLUE}"
        echo "███████╗███████╗"
        echo "╚════██║██╔════╝"
        echo "    ██║█████╗  "
        echo "    ██║██╔══╝  "
        echo "███████║███████╗"
        echo "╚══════╝╚══════╝"
        echo "${RESET}"

        if [ -f /etc/os-release ]; then
          . /etc/os-release
          echo "Welcome to ${PRETTY_NAME:-Bluefin}!"
          [ -n "$VERSION_ID" ] && echo "Version: $VERSION_ID"
        fi
      fi
    EOS

    bin.mkpath
    (bin / "bluefin-motd").write(motd_content)
    (bin / "bluefin-motd").chmod 0755

    # Install MOTD integration script
    motd_profile = <<~EOS
      # Bluefin MOTD Integration
      # This script runs the Bluefin MOTD banner on login

      if [ -t 0 ] && [ -x "#{bin}/bluefin-motd" ]; then
        #{bin}/bluefin-motd
      fi
    EOS

    (libexec / "motd" / "bluefin-motd.sh").write(motd_profile)
    (libexec / "motd" / "bluefin-motd.sh").chmod 0755

    # Copy CLI logos for MOTD display (optional)
    source_dir = buildpath / "packages/bluefin"
    logos_source = source_dir / "cli-logos/sixels"
    if logos_source.exist?
      (libexec / "motd" / "logos").mkpath
      Dir.glob(logos_source / "*").each do |f|
        next if File.directory?(f)

        (libexec / "motd" / "logos").install f
      end
    end
  end

  def caveats
    <<~EOS
      Bluefin MOTD has been installed!

      To automatically display the MOTD on login, add this to your shell profile
      (~/.zshrc, ~/.bashrc, etc.):

        if [ -x "#{bin}/bluefin-motd" ]; then
          #{bin}/bluefin-motd
        fi

      Or manually run:
        bluefin-motd

      CLI logos for MOTD display are available in:
        #{libexec}/motd/logos/
    EOS
  end

  test do
    assert_predicate bin / "bluefin-motd", :executable?
  end
end

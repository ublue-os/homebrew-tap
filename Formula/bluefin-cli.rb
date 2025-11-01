class BluefinCli < Formula
  desc "Complete shell experience: bling, MOTD, and premium CLI tools"
  homepage "https://github.com/ublue-os/packages"
  url "https://github.com/ublue-os/packages/archive/refs/tags/homebrew-2025-10-28-01-29-41.tar.gz"
  version "2025.10.28.01.29.41"
  sha256 "2de1cf76b2f76f90a7ef5a93b11e5cf1a24edbffc32f8db72849e75e0b61b92e"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^homebrew[._-](\d{4})[._-](\d{2})[._-](\d{2})[._-](\d{2})[._-](\d{2})[._-](\d{2})$/i)
    strategy :github_latest do |json, regex|
      json["tag_name"].scan(regex).map do |match|
        "#{match[0]}.#{match[1]}.#{match[2]}.#{match[3]}.#{match[4]}.#{match[5]}"
      end.first
    end
  end

  # CLI tools that bling integrates (core experience enhancements)
  depends_on "atuin"
  depends_on "bat"
  depends_on "eza"
  depends_on "starship"
  depends_on "ugrep"
  depends_on "zoxide"

  def install
    source_dir = buildpath / "packages"

    # Install CLI logos
    (libexec / "bluefin-logos/sixels").mkpath
    (libexec / "bluefin-logos/symbols").mkpath
    (libexec / "bluefin-logos/logos").mkpath

    Dir.glob(source_dir / "bluefin/cli-logos/sixels/*").each do |f|
      next if File.directory?(f)

      (libexec / "bluefin-logos/sixels").install f
    end

    Dir.glob(source_dir / "bluefin/cli-logos/symbols/*").each do |f|
      next if File.directory?(f)

      (libexec / "bluefin-logos/symbols").install f
    end

    Dir.glob(source_dir / "bluefin/cli-logos/logos/*").each do |f|
      next if File.directory?(f)

      (libexec / "bluefin-logos/logos").install f
    end

    # Install fastfetch configuration
    (libexec / "fastfetch").mkpath
    fastfetch_config = source_dir / "bluefin/fastfetch/fastfetch.jsonc"
    (libexec / "fastfetch").install fastfetch_config if fastfetch_config.exist?

    # Install bling scripts
    (libexec / "bling").mkpath

    bling_sh = source_dir / "ublue-bling/src/bling.sh"
    bling_fish = source_dir / "ublue-bling/src/bling.fish"

    if bling_sh.exist?
      (libexec / "bling" / "bling.sh").write bling_sh.read
      (libexec / "bling" / "bling.sh").chmod 0755
    end

    if bling_fish.exist?
      (libexec / "bling" / "bling.fish").write bling_fish.read
      (libexec / "bling" / "bling.fish").chmod 0755
    end

    # Install into share directory for user access
    (share / "bluefin").mkpath
    (share / "bluefin" / "bling").mkpath

    if bling_sh.exist?
      (share / "bluefin" / "bling" / "bling.sh").write bling_sh.read
      (share / "bluefin" / "bling" / "bling.sh").chmod 0755
    end

    if bling_fish.exist?
      (share / "bluefin" / "bling" / "bling.fish").write bling_fish.read
      (share / "bluefin" / "bling" / "bling.fish").chmod 0755
    end

    # Install MOTD banner script
    (libexec / "motd").mkpath
    motd_content = <<~EOS
      #!/bin/sh
      # Bluefin MOTD Banner

      # Terminal color codes
      BLUE="\\033[0;34m"
      LIGHT_BLUE="\\033[1;34m"
      RESET="\\033[0m"

      # Check if we're on Bluefin or related system
      if grep -q "bluefin\\|ublue" /etc/os-release 2>/dev/null; then
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

    (libexec / "motd" / "bluefin-motd.sh").write(motd_content)
    (libexec / "motd" / "bluefin-motd.sh").chmod 0755

    # Install bluefin-cli command for toggling bling and MOTD
    cli_command = <<~EOS
      #!/bin/sh
      # Bluefin CLI - Bling and MOTD manager

      BLING_MARKER="# bluefin-cli bling"
      MOTD_MARKER="# bluefin-cli motd"
      BLING_SH="#{libexec}/bling/bling.sh"
      MOTD_SH="#{libexec}/motd/bluefin-motd.sh"

      show_help() {
        cat << 'EOF'
      bluefin-cli - Bluefin shell experience manager

      Usage: bluefin-cli [COMMAND]

      Commands:
        bling SHELL [on|off]     Toggle bling for bash, zsh, or fish (default: on)
        motd [on|off]            Toggle MOTD display (default: on)
        status                   Show current configuration status
        help                     Show this help message

      Examples:
        bluefin-cli bling bash on     # Enable bling for bash
        bluefin-cli bling zsh off     # Disable bling for zsh
        bluefin-cli motd on           # Enable MOTD
        bluefin-cli status            # Check all settings
      EOF
      }

      toggle_bling() {
        shell=$1
        action=${2:-on}

        case "$shell" in
          bash)
            config="$HOME/.bashrc"
            source_line=". $BLING_SH"
            ;;
          zsh)
            config="$HOME/.zshrc"
            source_line=". $BLING_SH"
            ;;
          fish)
            config="$HOME/.config/fish/config.fish"
            source_line="source $BLING_SH"
            ;;
          *)
            echo "Unknown shell: $shell"
            return 1
            ;;
        esac

        if [ ! -f "$config" ]; then
          echo "Config file not found: $config"
          return 1
        fi

        if [ "$action" = "on" ]; then
          if grep -q "$BLING_MARKER" "$config" 2>/dev/null; then
            echo "Bling already enabled for $shell"
            return 0
          fi
          echo "" >> "$config"
          echo "$BLING_MARKER" >> "$config"
          echo "$source_line" >> "$config"
          echo "✓ Bling enabled for $shell"
        elif [ "$action" = "off" ]; then
          if ! grep -q "$BLING_MARKER" "$config" 2>/dev/null; then
            echo "Bling already disabled for $shell"
            return 0
          fi
          sed -i "/$BLING_MARKER/,+1d" "$config"
          echo "✓ Bling disabled for $shell"
        else
          echo "Unknown action: $action (use 'on' or 'off')"
          return 1
        fi
      }

      toggle_motd() {
        action=${1:-on}
        config="$HOME/.bashrc"

        if [ "$action" = "on" ]; then
          if grep -q "$MOTD_MARKER" "$config" 2>/dev/null; then
            echo "MOTD already enabled"
            return 0
          fi
          [ -f "$config" ] || touch "$config"
          echo "" >> "$config"
          echo "$MOTD_MARKER" >> "$config"
          echo "[ -x $MOTD_SH ] && $MOTD_SH" >> "$config"
          echo "✓ MOTD enabled"
        elif [ "$action" = "off" ]; then
          if ! grep -q "$MOTD_MARKER" "$config" 2>/dev/null; then
            echo "MOTD already disabled"
            return 0
          fi
          sed -i "/$MOTD_MARKER/,+1d" "$config"
          echo "✓ MOTD disabled"
        else
          echo "Unknown action: $action (use 'on' or 'off')"
          return 1
        fi
      }

      show_status() {
        echo "Bluefin CLI Status:"
        echo ""
        for shell in bash zsh fish; do
          case "$shell" in
            bash) config="$HOME/.bashrc" ;;
            zsh) config="$HOME/.zshrc" ;;
            fish) config="$HOME/.config/fish/config.fish" ;;
          esac
          if [ -f "$config" ] && grep -q "$BLING_MARKER" "$config" 2>/dev/null; then
            echo "  ✓ Bling: $shell (enabled)"
          else
            echo "  ✗ Bling: $shell (disabled)"
          fi
        done
        echo ""
        if [ -f "$HOME/.bashrc" ] && grep -q "$MOTD_MARKER" "$HOME/.bashrc" 2>/dev/null; then
          echo "  ✓ MOTD: enabled"
        else
          echo "  ✗ MOTD: disabled"
        fi
      }

      case "${1:-help}" in
        bling)
          toggle_bling "$2" "${3:-on}"
          ;;
        motd)
          toggle_motd "${2:-on}"
          ;;
        status)
          show_status
          ;;
        help|--help|-h)
          show_help
          ;;
        *)
          echo "Unknown command: $1"
          show_help
          exit 1
          ;;
      esac
    EOS

    bin.mkpath
    (bin / "bluefin-cli").write(cli_command)
    (bin / "bluefin-cli").chmod 0755
  end

  def caveats
    <<~EOS
      🚀 Bluefin CLI - Complete Shell Experience Enhanced!

      ✅ Installed Components:
      • Premium CLI Tools: eza, starship, atuin, zoxide, bat, ugrep
      • Bling Integration: Shell aliases, prompt, history, navigation
      • MOTD Banner: Bluefin welcome message
      • Management Command: bluefin-cli

      📁 Resources:
      • CLI Logos: #{libexec}/bluefin-logos/
      • Fastfetch Config: #{libexec}/fastfetch/
      • Bling Scripts: #{libexec}/bling/
      • MOTD Script: #{libexec}/motd/

      🔧 Setup Your Shell - Choose your shell and enable bling:

      BASH:
        bluefin-cli bling bash on && bluefin-cli motd on
      ZSH:
        bluefin-cli bling zsh on && bluefin-cli motd on
      FISH:
        bluefin-cli bling fish on; bluefin-cli motd on

      📋 Management Commands:

        bluefin-cli bling bash on       # Enable bling for bash
        bluefin-cli bling bash off      # Disable bling for bash
        bluefin-cli motd on             # Enable MOTD banner
        bluefin-cli motd off            # Disable MOTD banner
        bluefin-cli status              # Show current configuration
        bluefin-cli help                # Show all available commands

      ✨ After setup, restart your terminal or re-source your shell config
      to activate all bling enhancements and see the MOTD banner!

      📖 Docs: https://docs.projectbluefin.io/command-line
    EOS
  end

  test do
    assert_predicate libexec / "bling" / "bling.sh", :file?
    assert_predicate libexec / "bling" / "bling.fish", :file?
    assert_predicate libexec / "bluefin-logos", :directory?
    assert_predicate libexec / "fastfetch", :directory?
    assert_predicate libexec / "motd" / "bluefin-motd.sh", :file?
    assert_predicate bin / "bluefin-cli", :executable?
  end
end

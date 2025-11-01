class BluefinCli < Formula
  desc "Complete shell experience: bling, MOTD, and premium CLI tools"
  homepage "https://github.com/ublue-os/packages"
  url "https://github.com/ublue-os/packages/archive/refs/tags/homebrew-2025-10-28-01-29-41.tar.gz"
  version "2025.10.28.01.29.41"
  sha256 "fdc1a5ac6bfa48c710abe3ad9286ce1129cb7e4c3acb9978aaecf88157fbc6b4"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/homebrew[._-](\d{4}[._-]\d{2}[._-]\d{2}[._-]\d{2}[._-]\d{2}[._-]\d{2})/i)
    strategy :github_latest
  end

  depends_on "atuin"
  depends_on "bat"
  depends_on "eza"
  depends_on "glow"
  depends_on "jq"
  depends_on "starship"
  depends_on "ugrep"
  depends_on "zoxide"

  def install
    # Needed for JSON.pretty_generate
    require "json"
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

    # Install MOTD system (simplified portable version)
    (libexec / "motd").mkpath
    (libexec / "motd" / "themes").mkpath
    (libexec / "motd" / "tips").mkpath

    # Create a clean, portable MOTD script from scratch
    motd_script_content = <<~'MOTD_SCRIPT'
      #!/usr/bin/env bash

      SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
      TIP_DIRECTORY="${TIP_DIRECTORY:-$SELF_DIR/tips}"
      IMAGE_INFO="${IMAGE_INFO:-$SELF_DIR/image-info.json}"
      TEMPLATE_FILE="${TEMPLATE_FILE:-$SELF_DIR/template.md}"
      THEMES_DIRECTORY="${THEMES_DIRECTORY:-$SELF_DIR/themes}"
      DEFAULT_THEME="${DEFAULT_THEME:-slate}"

      # Get a random tip (portable - no shuf needed)
      if [ -d "$TIP_DIRECTORY" ] && [ -n "$(ls -A "$TIP_DIRECTORY"/*.md 2>/dev/null)" ]; then
        # Pick a random file, then read its content
        TIP_FILE="$(ls "$TIP_DIRECTORY"/*.md 2>/dev/null | awk 'BEGIN {srand()} {line[NR] = $0} END {if (NR > 0) print line[int(rand() * NR) + 1]}')"
        TIP="$(cat "$TIP_FILE" 2>/dev/null)"
      else
        TIP=""
      fi

      # Read image info or detect OS
      if command -v jq >/dev/null 2>&1 && [ -f "$IMAGE_INFO" ]; then
        IMAGE_NAME="$(jq -r '."image-name"' "$IMAGE_INFO" 2>/dev/null || echo "bluefin-cli")"
        IMAGE_TAG="$(jq -r '."image-tag"' "$IMAGE_INFO" 2>/dev/null || echo "homebrew")"
      else
        # Detect OS and version for non-Bluefin systems
        if [ "$(uname)" = "Darwin" ]; then
          IMAGE_NAME="macOS"
          IMAGE_TAG="$(sw_vers -productVersion 2>/dev/null || echo "unknown")"
        elif [ -f /etc/os-release ]; then
          . /etc/os-release
          IMAGE_NAME="${NAME:-Linux}"
          IMAGE_TAG="${VERSION_ID:-${VERSION:-unknown}}"
        else
          IMAGE_NAME="$(uname -s)"
          IMAGE_TAG="$(uname -r)"
        fi
      fi

      # Process template
      if [ ! -f "$TEMPLATE_FILE" ]; then
        echo "Error: Template file not found: $TEMPLATE_FILE" >&2
        exit 1
      fi

      # Simple variable substitution
      CONTENT="$(cat "$TEMPLATE_FILE" | \
        sed "s|%IMAGE_NAME%|$IMAGE_NAME|g" | \
        sed "s|%IMAGE_TAG%|$IMAGE_TAG|g" | \
        sed "s|%TIP%|$TIP|g" | \
        sed "s|%KEY_WARN%||g" | \
        tr '~' '\n')"

      # Render with glow if available, otherwise plain text
      if command -v glow >/dev/null 2>&1 && [ -f "$THEMES_DIRECTORY/${DEFAULT_THEME}.json" ]; then
        echo "$CONTENT" | glow -s "$THEMES_DIRECTORY/${DEFAULT_THEME}.json" -w "$(tput cols 2>/dev/null || echo 80)" -
      else
        # Plain text fallback
        echo "$CONTENT" | sed -E 's/\*\*([^*]+)\*\*/\1/g; s/`([^`]+)`/\1/g; s/^#+\s*//; s/^[│┃┆┊]\s*//; s/^[•-]\s*/  • /'
      fi
    MOTD_SCRIPT

    (libexec / "motd" / "bluefin-motd").write(motd_script_content)
    (libexec / "motd" / "bluefin-motd").chmod 0755

    # Install MOTD template from bluefin repository
    template_content = <<~EOS
      # 󱍢 Welcome to Bluefin
      󱋩 `%IMAGE_NAME%:%IMAGE_TAG%`

      |  Command | Description |
      | ------- | ----------- |
      | `bluefin-cli bling bash on`  | Enable terminal bling for bash  |
      | `bluefin-cli status` | Show current configuration |
      | `bluefin-cli help` | Show all available commands |
      | `brew help` | Manage command line packages |

      %TIP%

      - **󰊤** [Issues](https://issues.projectbluefin.io)
      - **󰊤** [Ask Bluefin](https://ask.projectbluefin.io)
      - **󰈙** [Documentation](http://docs.projectbluefin.io)


      %KEY_WARN%
    EOS

    (libexec / "motd" / "template.md").write(template_content)

    # Install theme files
    themes_source = source_dir / "ublue-motd/src/themes"
    if themes_source.directory?
      Dir.glob(themes_source / "*.json").each do |theme|
        (libexec / "motd" / "themes").install theme
      end
    end

    # Create image-info.json with OS detection
    os_name = if OS.mac?
      "macOS"
    elsif OS.linux?
      os_release = Pathname.new("/etc/os-release")
      if os_release.exist?
        os_release.read.match(/^NAME="?([^"\n]+)"?/m)&.captures&.first || "Linux"
      else
        "Linux"
      end
    else
      "Unknown"
    end

    os_version = if OS.mac?
      Utils.safe_popen_read("sw_vers", "-productVersion").strip
    elsif OS.linux?
      os_release = Pathname.new("/etc/os-release")
      if os_release.exist?
        os_release.read.match(/^VERSION_ID="?([^"\n]+)"?/m)&.captures&.first ||
          os_release.read.match(/^VERSION="?([^"\n]+)"?/m)&.captures&.first || "unknown"
      else
        "unknown"
      end
    else
      "unknown"
    end

    image_info = {
      "image-name"     => os_name,
      "image-tag"      => os_version,
      "image-flavor"   => "homebrew",
      "image-vendor"   => "bluefin-cli",
      "fedora-version" => "N/A",
    }
    (libexec / "motd" / "image-info.json").write(JSON.pretty_generate(image_info))

    # Create default motd.json config
    motd_config = {
      "tips-directory"   => "#{libexec}/motd/tips",
      "check-outdated"   => "false",
      "image-info-file"  => "#{libexec}/motd/image-info.json",
      "default-theme"    => "slate",
      "template-file"    => "#{libexec}/motd/template.md",
      "themes-directory" => "#{libexec}/motd/themes",
    }
    (libexec / "motd" / "motd.json").write(JSON.pretty_generate(motd_config))

    # Install sample tips (cross-platform friendly)
    tips = [
      "Use `brew search` and `brew install` to install packages. Homebrew will take care of updates automatically",
      "`tldr vim` will give you the basic rundown on commands for a given tool",
      "Performance profiling tools are built-in: try `top`, `htop`, and other debugging tools",
      "Switch shells safely: change your shell in Terminal settings instead of system-wide",
      "Container development is OS-agnostic - your devcontainers work on Linux, macOS, and Windows",
      "Use `docker compose` for multi-container development if devcontainers don't fit your workflow",
      "Bluefin separates the OS from your development environment - embrace the cloud-native workflow",
      "Check out DevPod for open-source, client-only development environments that work with any IDE",
      "Develop with devcontainers! Use `devcontainer.json` files in your projects for isolated, " \
      "reproducible environments",
      "VS Code comes with devcontainers extension pre-installed - perfect for containerized development",
    ]

    tips.each_with_index do |tip, idx|
      (libexec / "motd" / "tips" / "#{format("%02d", idx + 10)}-tip.md").write(tip)
    end

    # Install bluefin-cli command for toggling bling and MOTD
    cli_command = <<~EOS
      #!/bin/sh
      # Bluefin CLI - Bling and MOTD manager

      remove_block() {
        file="$1"
        marker="$2"
        lines="${3:-1}"
        awk -v m="$marker" -v n="$lines" '
          skip>0 { skip--; next }
          $0 ~ m { skip=n; next }
          { print }
        ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
      }

      BLING_MARKER="# bluefin-cli bling"
      MOTD_MARKER="# bluefin-cli motd"
      BLING_SH="#{opt_libexec}/bling/bling.sh"
      BLING_FISH="#{opt_libexec}/bling/bling.fish"
      MOTD_SH="#{opt_libexec}/motd/bluefin-motd"

      show_help() {
        cat << 'EOF'
      bluefin-cli - Bluefin shell experience manager

      Usage: bluefin-cli [COMMAND]

      Commands:
        bling SHELL [on|off]     Toggle bling for bash, zsh, or fish (default: on)
        motd [SHELL|all] [on|off]  Toggle MOTD for bash, zsh, fish, or all (default: all on)
        install NAME|PATH         Install a Brew bundle by name (ai, cli, fonts, k8s) or local path
        status                   Show current configuration status
        help                     Show this help message

      Examples:
        bluefin-cli bling bash on     # Enable bling for bash
        bluefin-cli bling zsh off     # Disable bling for zsh
        bluefin-cli motd zsh on       # Enable MOTD for zsh
        bluefin-cli motd all off      # Disable MOTD for all shells
        bluefin-cli install ai        # Install the Bluefin AI Brew bundle
        bluefin-cli install ./Brewfile  # Install from a local Brewfile path
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
            source_line="source $BLING_FISH"
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
          remove_block "$config" "$BLING_MARKER" 1
          echo "✓ Bling disabled for $shell"
        else
          echo "Unknown action: $action (use 'on' or 'off')"
          return 1
        fi
      }

      toggle_motd() {
        shell_or_action=${1:-all}
        action=${2:-on}

        # If first arg is on/off, treat as action and target all shells
        case "$shell_or_action" in
          on|off)
            action="$shell_or_action"
            shell_or_action="all"
            ;;
        esac

        enable_for_shell() {
          s="$1"; a="$2"
          case "$s" in
            bash)
              config="$HOME/.bashrc"
              line="[ -x #{opt_libexec}/motd/bluefin-motd ] && #{opt_libexec}/motd/bluefin-motd"
              lines_to_remove=1
              ;;
            zsh)
              config="$HOME/.zshrc"
              line="[ -x #{opt_libexec}/motd/bluefin-motd ] && #{opt_libexec}/motd/bluefin-motd"
              lines_to_remove=1
              ;;
            fish)
              config="$HOME/.config/fish/config.fish"
              line="if status is-interactive; and test -x #{opt_libexec}/motd/bluefin-motd; #{opt_libexec}/motd/bluefin-motd; end"
              lines_to_remove=2
              ;;
            *)
              echo "Unknown shell: $s" >&2; return 1 ;;
          esac

          [ -f "$config" ] || mkdir -p "$(dirname "$config")" && touch "$config"

          if [ "$a" = "on" ]; then
            if grep -q "$MOTD_MARKER" "$config" 2>/dev/null; then
              echo "MOTD already enabled for $s"
            else
              {
                echo ""
                echo "$MOTD_MARKER"
                echo "$line"
              } >> "$config"
              echo "✓ MOTD enabled for $s"
            fi
          elif [ "$a" = "off" ]; then
            if ! grep -q "$MOTD_MARKER" "$config" 2>/dev/null; then
              echo "MOTD already disabled for $s"
            else
              remove_block "$config" "$MOTD_MARKER" "$lines_to_remove"
              echo "✓ MOTD disabled for $s"
            fi
          else
            echo "Unknown action: $a (use 'on' or 'off')"
            return 1
          fi
        }

        shells="bash zsh fish"
        if [ "$shell_or_action" != "all" ]; then
          shells="$shell_or_action"
        fi
        for s in $shells; do
          enable_for_shell "$s" "$action"
        done
      }

      install_bundle() {
        name_or_path="$1"
        if [ -z "$name_or_path" ]; then
          echo "Usage: bluefin-cli install <ai|cli|fonts|k8s|PATH>"
          return 1
        fi

        if ! command -v brew >/dev/null 2>&1; then
          echo "Homebrew not found on PATH. Please install Homebrew first: https://brew.sh"
          return 1
        fi

        # If contains a slash, treat as a filesystem path
        if printf '%s' "$name_or_path" | grep -q "/"; then
          brewfile="$name_or_path"
          if [ ! -f "$brewfile" ]; then
            echo "Brewfile path not found: $brewfile"
            return 1
          fi
        else
          # Map known bundle names to Bluefin Brewfiles on GitHub
          base_url="${BLUEFIN_BREW_BASE:-https://raw.githubusercontent.com/ublue-os/bluefin/refs/heads/main/brew}"
          case "$name_or_path" in
            ai)    file="bluefin-ai.Brewfile" ;;
            cli)   file="bluefin-cli.Brewfile" ;;
            fonts) file="bluefin-fonts.Brewfile" ;;
            k8s)   file="bluefin-k8s.Brewfile" ;;
            list)
              echo "ai:"
              echo "   AI tools: Goose, Codex, Gemini, Ramalama, etc."
              echo "cli:"
              echo "    CLI fun: GitHub CLI, chezmoi, etc."
              echo "fonts:"
              echo "    Fonts: Fira Code, JetBrains Mono, etc."
              echo "k8s:"
              echo "    Kubernetes tools: kubectl, k9s, kind, etc."
              return 0
              ;;
            all)
              bluefin-cli install ai
              bluefin-cli install cli
              bluefin-cli install fonts
              bluefin-cli install k8s
              return 0
              ;;
            *)
              echo "Unknown bundle: $name_or_path"
              echo "Use one of: ai, cli, fonts, k8s, or provide a path"
              return 1
              ;;
          esac
          url="$base_url/$file"
          brewfile="${TMPDIR:-/tmp}/$file"
          if ! curl -fsSL "$url" -o "$brewfile"; then
            echo "Failed to download: $url"
            return 1
          fi
        fi

        echo "Installing bundle from: $brewfile"
        BREW_NONINTERACTIVE=1 brew bundle --file="$brewfile"
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
        for shell in bash zsh fish; do
          case "$shell" in
            bash) config="$HOME/.bashrc" ;;
            zsh) config="$HOME/.zshrc" ;;
            fish) config="$HOME/.config/fish/config.fish" ;;
          esac
          if [ -f "$config" ] && grep -q "$MOTD_MARKER" "$config" 2>/dev/null; then
            echo "  ✓ MOTD: $shell (enabled)"
          else
            echo "  ✗ MOTD: $shell (disabled)"
          fi
        done
      }

      case "${1:-help}" in
        bling)
          toggle_bling "$2" "${3:-on}"
          ;;
        motd)
          toggle_motd "${2:-all}" "${3:-on}"
          ;;
        install)
          install_bundle "$2"
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
      To enable bling and MOTD, run:
        bluefin-cli bling <bash|zsh|fish> on
        bluefin-cli motd on

      View all commands:
        bluefin-cli help
    EOS
  end

  test do
    assert_predicate libexec / "bling" / "bling.sh", :file?
    assert_predicate libexec / "bling" / "bling.fish", :file?
    assert_predicate libexec / "bluefin-logos", :directory?
    assert_predicate libexec / "fastfetch", :directory?
    assert_predicate libexec / "motd" / "bluefin-motd", :executable?
    assert_predicate libexec / "motd" / "template.md", :file?
    assert_predicate libexec / "motd" / "themes", :directory?
    assert_predicate libexec / "motd" / "tips", :directory?
    assert_predicate libexec / "motd" / "motd.json", :file?
    assert_predicate libexec / "motd" / "image-info.json", :file?
    assert_predicate bin / "bluefin-cli", :executable?

    # Test MOTD script can run (even without glow/jq)
    system libexec / "motd" / "bluefin-motd"
  end
end

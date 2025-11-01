class BluefinCli < Formula
  desc "Bluefin CLI tools, logos, fastfetch config, and shell integration (bling)"
  homepage "https://github.com/ublue-os/packages"
  url "https://github.com/ublue-os/packages/archive/refs/tags/homebrew-2025-10-28-01-29-41.tar.gz"
  version "0.2.6"
  sha256 "2de1cf76b2f76f90a7ef5a93b11e5cf1a24edbffc32f8db72849e75e0b61b92e"
  license "CC-BY-SA"

  depends_on "jq"

  def install
    source_dir = buildpath / "packages/bluefin"

    # CLI logos
    (libexec / "bluefin-logos/sixels").mkpath
    (libexec / "bluefin-logos/symbols").mkpath
    (libexec / "bluefin-logos/logos").mkpath

    Dir.glob(source_dir / "cli-logos/sixels/*").each do |f|
      next if File.directory?(f)

      (libexec / "bluefin-logos/sixels").install f
    end

    Dir.glob(source_dir / "cli-logos/symbols/*").each do |f|
      next if File.directory?(f)

      (libexec / "bluefin-logos/symbols").install f
    end

    Dir.glob(source_dir / "cli-logos/logos/*").each do |f|
      next if File.directory?(f)

      (libexec / "bluefin-logos/logos").install f
    end

    # Fastfetch configuration
    (libexec / "fastfetch").mkpath
    fastfetch_config = source_dir / "fastfetch/fastfetch.jsonc"
    (libexec / "fastfetch").install fastfetch_config if fastfetch_config.exist?

    # Install bling (shell integration helper)
    bin.mkpath
    bling_script = create_bling_cli_script
    (bin / "bluefin-cli").write(bling_script)
    (bin / "bluefin-cli").chmod 0755

    # Create bling shell script files
    (libexec / "bling").mkpath
    (libexec / "bling").install create_bling_sh_script, "bling.sh"
    (libexec / "bling").install create_bling_fish_script, "bling.fish"

    # Install into share directory for user access
    (share / "bluefin").mkpath
    FileUtils.cp_r(libexec / "bluefin-logos", share / "bluefin/")
    FileUtils.cp_r(libexec / "fastfetch", share / "bluefin/")
    FileUtils.cp_r(libexec / "bling", share / "bluefin/")
  end

  def create_bling_cli_script
    <<~BASH
      #!/usr/bin/env bash
      
      set -eou pipefail
      
      # Bluefin CLI - Cross-platform bling integration
      # Supports: bash, zsh, fish on macOS and Linux
      
      BLING_CLI_DIRECTORY="#{opt_libexec}/bling"
      
      # Colors for output
      bold="\\033[1m"
      red="\\033[0;31m"
      green="\\033[0;32m"
      blue="\\033[0;34m"
      normal="\\033[0m"
      
      # Exit handler
      function exiting() {
          printf "%s%sExiting...%s\\n" "${red}" "${bold}" "${normal}"
          printf "Rerun with: %s%sbluefin-cli%s\\n" "${blue}" "${bold}" "${normal}"
          exit 0
      }
      
      # Trap CTRL+C
      function ctrl_c() {
          printf "\\n%s\\n" "Signal SIGINT caught"
          exiting
      }
      
      # Check if bling is already sourced
      # Returns 0 if installed, 1 if not
      function is_bling_installed() {
          local shell="$1"
          local target_file bling_source
          
          case "${shell}" in
              fish)
                  bling_source="bling.fish"
                  target_file="${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"
                  ;;
              zsh)
                  bling_source="bling.sh"
                  target_file="${ZDOTDIR:-$HOME}/.zshrc"
                  ;;
              bash)
                  bling_source="bling.sh"
                  target_file="$HOME/.bashrc"
                  ;;
              *)
                  echo "Unknown shell: $shell"
                  return 1
                  ;;
          esac
          
          [[ -f "$target_file" ]] && grep -q "source $BLING_CLI_DIRECTORY/$bling_source" "$target_file"
      }
      
      # Add bling to shell config
      function add_bling() {
          local shell="$1"
          
          echo "Setting up your shell 🐚"
          
          case "${shell}" in
              fish)
                  echo "Adding bling to config.fish 🐟"
                  cat >> "${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish" << 'EOF'
      
      ### bluefin-cli bling.fish source start
      test -f #{opt_libexec}/bling/bling.fish && source #{opt_libexec}/bling/bling.fish
      ### bluefin-cli bling.fish source end
      EOF
                  ;;
              zsh)
                  echo "Adding bling to .zshrc 💤"
                  cat >> "${ZDOTDIR:-$HOME}/.zshrc" << 'EOF'
      
      ### bluefin-cli bling.sh source start
      test -f #{opt_libexec}/bling/bling.sh && source #{opt_libexec}/bling/bling.sh
      ### bluefin-cli bling.sh source end
      EOF
                  ;;
              bash)
                  echo "Adding bling to .bashrc 💥"
                  cat >> "$HOME/.bashrc" << 'EOF'
      
      ### bluefin-cli bling.sh source start
      test -f #{opt_libexec}/bling/bling.sh && source #{opt_libexec}/bling/bling.sh
      ### bluefin-cli bling.sh source end
      EOF
                  ;;
              *)
                  echo "Unknown shell: $shell"
                  return 1
                  ;;
          esac
      }
      
      # Remove bling from shell config
      function remove_bling() {
          local shell="$1"
          
          case "${shell}" in
              fish)
                  sed -i.bak '/### bluefin-cli bling.fish source start/,/### bluefin-cli bling.fish source end/d' \\
                      "${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"
                  ;;
              zsh)
                  sed -i.bak '/### bluefin-cli bling.sh source start/,/### bluefin-cli bling.sh source end/d' \\
                      "${ZDOTDIR:-$HOME}/.zshrc"
                  ;;
              bash)
                  sed -i.bak '/### bluefin-cli bling.sh source start/,/### bluefin-cli bling.sh source end/d' \\
                      "$HOME/.bashrc"
                  ;;
          esac
      }
      
      # Main menu
      function main() {
          local shell reentry choice
          shell=$(basename "$SHELL")
          reentry="$1"
          
          if [[ -n "${reentry:-}" ]]; then
              printf "%s%s%s\\n\\n" "${bold}" "$reentry" "${normal}"
          fi
          
          printf "Shell:\\t%s%s%s%s\\n" "${green}" "${bold}" "${shell}" "${normal}"
          
          if is_bling_installed "${shell}"; then
              printf "Bling:\\t%s%sEnabled%s\\n" "${green}" "${bold}" "${normal}"
          else
              printf "Bling:\\t%s%sDisabled%s\\n" "${red}" "${bold}" "${normal}"
          fi
          
          echo ""
          echo "What would you like to do?"
          echo "1) Enable bling"
          echo "2) Disable bling"
          echo "3) Exit"
          
          read -p "Enter choice (1-3): " choice
          
          case "$choice" in
              1)
                  if is_bling_installed "${shell}"; then
                      main "Bling is already enabled..."
                  else
                      trap ctrl_c SIGINT
                      add_bling "${shell}"
                      printf "%s%sInstallation Complete!%s Please close and reopen your terminal.\\n" \\
                          "${green}" "${bold}" "${normal}"
                      exit 0
                  fi
                  ;;
              2)
                  if ! is_bling_installed "${shell}"; then
                      main "Bling is not yet enabled..."
                  else
                      trap ctrl_c SIGINT
                      remove_bling "${shell}"
                      printf "%s%sBling Removed!%s Please close and reopen your terminal.\\n" \\
                          "${red}" "${bold}" "${normal}"
                      exit 0
                  fi
                  ;;
              *)
                  exiting
                  ;;
          esac
      }
      
      main ""
    BASH
  end

  def create_bling_sh_script
    <<~BASH
      #!/usr/bin/env bash
      
      # Bluefin CLI Bling - bash/zsh shell enhancements
      # Cross-platform (macOS/Linux)
      
      # Define prompt styling
      if [[ -n "${ZSH_VERSION}" ]]; then
          # Zsh
          export PS1='%F{blue}%n%f@%F{green}%m%f:%F{cyan}%~%f%F{yellow}$(__git_ps1)%f $ '
      else
          # Bash
          export PS1='\\[\\033[0;34m\\]\\u\\[\\033[0m\\]@\\[\\033[0;32m\\]\\h\\[\\033[0m\\]:\\[\\033[0;36m\\]\\w\\[\\033[0m\\]\\[\\033[0;33m\\]$(__git_ps1)\\[\\033[0m\\] \\$ '
      fi
      
      # Git prompt helper
      __git_ps1() {
          local status=$(git status --porcelain 2>/dev/null)
          if [[ -n "$status" ]]; then
              echo " (git:*)"
          elif [[ -d .git ]]; then
              echo " (git)"
          fi
      }
      
      # Useful aliases
      alias ls='ls -lah'
      alias ll='ls -l'
      alias la='ls -la'
      alias grep='grep --color=auto'
      
      # macOS specific
      if [[ "$OSTYPE" == "darwin"* ]]; then
          alias sed='sed -i .bak'
          alias du='du -h'
          alias df='df -h'
      else
          # Linux specific
          alias sed='sed -i'
          alias du='du -h'
          alias df='df -h'
      fi
    BASH
  end

  def create_bling_fish_script
    <<~FISH
      #!/usr/bin/env fish
      
      # Bluefin CLI Bling - fish shell enhancements
      # Cross-platform (macOS/Linux)
      
      # Git prompt
      function __bluefin_git_status
          set -l status (git status --porcelain 2>/dev/null)
          if test -n "$status"
              echo " (git:*)"
          else if test -d .git
              echo " (git)"
          end
      end
      
      # Prompt
      function fish_prompt
          set -l last_status $status
          set -l cwd (prompt_pwd)
          set -l git_status (__bluefin_git_status)
          
          set_color blue
          echo -n $USER
          set_color normal
          echo -n "@"
          set_color green
          echo -n (hostname)
          set_color normal
          echo -n ":"
          set_color cyan
          echo -n $cwd
          set_color yellow
          echo -n $git_status
          set_color normal
          echo -n " > "
      end
      
      # Useful aliases
      alias ls='ls -lah'
      alias ll='ls -l'
      alias la='ls -la'
      alias grep='grep --color=auto'
      
      # Platform-specific aliases
      switch (uname)
          case Darwin
              # macOS
              alias sed='sed -i .bak'
              alias du='du -h'
              alias df='df -h'
          case Linux
              # Linux
              alias sed='sed -i'
              alias du='du -h'
              alias df='df -h'
      end
    FISH
  end

  def caveats
    <<~EOS
      Bluefin CLI has been installed with bling shell integration!

      📦 Resources Installed:
      • CLI Logos: #{share}/bluefin/bluefin-logos/
      • Fastfetch Config: #{share}/bluefin/fastfetch/fastfetch.jsonc
      • Bling Scripts: #{opt_libexec}/bling/

      🚀 Quick Setup:
      1. Enable bling shell integration:
           bluefin-cli

      2. Or manually setup fastfetch:
           mkdir -p ~/.config/fastfetch
           cp #{share}/bluefin/fastfetch/fastfetch.jsonc ~/.config/fastfetch/config.jsonc

      📝 Manual Shell Integration:
      Add this to your shell config (~/.bashrc, ~/.zshrc, or config.fish):
           source #{opt_libexec}/bling/bling.sh   (bash/zsh)
           source #{opt_libexec}/bling/bling.fish (fish)

      🔗 Documentation: https://docs.projectbluefin.io/command-line
    EOS
  end

  test do
    assert_predicate bin / "bluefin-cli", :executable?
    assert_predicate libexec / "bling" / "bling.sh", :file?
    assert_predicate libexec / "bling" / "bling.fish", :file?
    assert_predicate share / "bluefin" / "bluefin-logos", :directory?
    assert_predicate share / "bluefin" / "fastfetch", :directory?
  end
end

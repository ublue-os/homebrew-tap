class BluefinCli < Formula
  desc "Shell integration with eza, starship, atuin, zoxide, bat, and ugrep"
  homepage "https://github.com/ublue-os/packages"
  url "https://github.com/ublue-os/packages/archive/refs/tags/homebrew-2025-10-28-01-29-41.tar.gz"
  version "0.2.6"
  sha256 "2de1cf76b2f76f90a7ef5a93b11e5cf1a24edbffc32f8db72849e75e0b61b92e"
  license "Apache-2.0"

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
  end

  def post_install
    # Detect installed shells and add bling to their configs
    shells = detect_installed_shells

    shells.each do |shell_name|
      case shell_name
      when "bash"
        setup_bash
      when "zsh"
        setup_zsh
      when "fish"
        setup_fish
      end
    end
  end

  def post_uninstall
    # Remove bling from shell configs on uninstall
    remove_from_bash
    remove_from_zsh
    remove_from_fish
  end

  def caveats
    <<~EOS
      🚀 Bluefin CLI - Complete Shell Experience Enhanced!

      Your shell has been automatically configured with these premium tools:

      📦 Installed Tools:
      • eza - Modern ls replacement with icons and colors
      • starship - Cross-shell prompt with git integration
      • atuin - Enhanced shell history with search
      • zoxide - Smart directory navigation (better cd)
      • bat - Syntax-highlighted cat replacement
      • ugrep - Fast, colorful grep with regex support

      🎨 Resources Installed:
      • CLI Logos: #{libexec}/bluefin-logos/
      • Fastfetch Config: #{libexec}/fastfetch/
      • Bling Scripts: #{libexec}/bling/

      ✨ What Just Happened:
      1. All premium CLI tools installed
      2. Shell configuration (bash/zsh/fish) updated automatically
      3. Tools are ready to use immediately!

      📝 Shell Configuration:
      Your shell configs have been updated with bling integration:

      Bash/Zsh:
        ~/.bashrc and ~/.zshrc now source #{libexec}/bling/bling.sh

      Fish:
        ~/.config/fish/config.fish now sources #{libexec}/bling/bling.fish

      🔗 Documentation: https://docs.projectbluefin.io/command-line
    EOS
  end

  test do
    assert_predicate libexec / "bling" / "bling.sh", :file?
    assert_predicate libexec / "bling" / "bling.fish", :file?
    assert_predicate libexec / "bluefin-logos", :directory?
    assert_predicate libexec / "fastfetch", :directory?
  end

  private

  def detect_installed_shells
    shells = []
    shells << "bash" if system("command -v bash > /dev/null 2>&1")
    shells << "zsh" if system("command -v zsh > /dev/null 2>&1")
    shells << "fish" if system("command -v fish > /dev/null 2>&1")
    shells
  end

  def setup_bash
    bashrc = Pathname.home / ".bashrc"
    bling_source = "[ -f #{libexec}/bling/bling.sh ] && . #{libexec}/bling/bling.sh"

    return unless bashrc.exist?
    return if bashrc.read.include?(bling_source)

    bashrc.append_lines("\n# bluefin-cli bling\n#{bling_source}\n")
  end

  def setup_zsh
    zshrc = Pathname.new(ENV["ZDOTDIR"] || (Pathname.home / ".zshrc"))
    bling_source = "[ -f #{libexec}/bling/bling.sh ] && . #{libexec}/bling/bling.sh"

    return unless zshrc.exist?
    return if zshrc.read.include?(bling_source)

    zshrc.append_lines("\n# bluefin-cli bling\n#{bling_source}\n")
  end

  def setup_fish
    fish_config = Pathname.new(ENV["XDG_CONFIG_HOME"] || (Pathname.home / ".config")) / "fish" / "config.fish"
    bling_source = "[ -f #{libexec}/bling/bling.fish ] && . #{libexec}/bling/bling.fish"

    return unless fish_config.exist?
    return if fish_config.read.include?(bling_source)

    fish_config.append_lines("\n# bluefin-cli bling\n#{bling_source}\n")
  end

  def remove_from_bash
    bashrc = Pathname.home / ".bashrc"
    return unless bashrc.exist?

    content = bashrc.read
    return unless content.include?("# bluefin-cli bling")

    new_content = content.gsub(/\n# bluefin-cli bling\n\[ -f .* bling\.sh \] && \. .*\n/, "\n")
    bashrc.write(new_content)
  end

  def remove_from_zsh
    zshrc = Pathname.new(ENV["ZDOTDIR"] || (Pathname.home / ".zshrc"))
    return unless zshrc.exist?

    content = zshrc.read
    return unless content.include?("# bluefin-cli bling")

    new_content = content.gsub(/\n# bluefin-cli bling\n\[ -f .* bling\.sh \] && \. .*\n/, "\n")
    zshrc.write(new_content)
  end

  def remove_from_fish
    fish_config = Pathname.new(ENV["XDG_CONFIG_HOME"] || (Pathname.home / ".config")) / "fish" / "config.fish"
    return unless fish_config.exist?

    content = fish_config.read
    return unless content.include?("# bluefin-cli bling")

    new_content = content.gsub(/\n# bluefin-cli bling\n\[ -f .* bling\.fish \] && \. .*\n/, "\n")
    fish_config.write(new_content)
  end
end

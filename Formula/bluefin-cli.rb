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

  def caveats
    bash_cmd = "echo '. #{libexec}/bling/bling.sh' >> ~/.bashrc"
    zsh_cmd = "echo '. #{libexec}/bling/bling.sh' >> ~/.zshrc"
    fish_cmd = "echo 'source #{libexec}/bling/bling.fish' >> ~/.config/fish/config.fish"

    <<~EOS
      🚀 Bluefin CLI - Complete Shell Experience Enhanced!

      ✅ Installed Tools & Resources:
      • eza - Modern ls replacement with icons and colors
      • starship - Cross-shell prompt with git integration
      • atuin - Enhanced shell history with search
      • zoxide - Smart directory navigation (better cd)
      • bat - Syntax-highlighted cat replacement
      • ugrep - Fast, colorful grep with regex support

      📁 Resources:
      • CLI Logos: #{libexec}/bluefin-logos/
      • Fastfetch Config: #{libexec}/fastfetch/
      • Bling Scripts: #{libexec}/bling/

      🔧 Setup Instructions - Choose your shell:

      BASH:
        #{bash_cmd}

      ZSH:
        #{zsh_cmd}

      FISH:
        #{fish_cmd}

      After running the appropriate command for your shell, restart your terminal or run:
        source ~/.bashrc           # for bash
        source ~/.zshrc            # for zsh
        source ~/.config/fish/config.fish  # for fish

      Then all the premium tools will be ready to use!

      � Docs: https://docs.projectbluefin.io/command-line
    EOS
  end

  test do
    assert_predicate libexec / "bling" / "bling.sh", :file?
    assert_predicate libexec / "bling" / "bling.fish", :file?
    assert_predicate libexec / "bluefin-logos", :directory?
    assert_predicate libexec / "fastfetch", :directory?
  end
end

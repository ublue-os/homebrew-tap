class BluefinCli < Formula
  desc "Bluefin CLI shell integration (bling) with eza, starship, atuin, and zoxide"
  homepage "https://github.com/ublue-os/packages"
  url "https://github.com/ublue-os/packages/archive/refs/tags/homebrew-2025-10-28-01-29-41.tar.gz"
  version "0.2.6"
  sha256 "2de1cf76b2f76f90a7ef5a93b11e5cf1a24edbffc32f8db72849e75e0b61b92e"
  license "CC-BY-SA"

  # Optional tools that bling will use if available
  depends_on "eza" => :optional
  depends_on "starship" => :optional
  depends_on "atuin" => :optional
  depends_on "zoxide" => :optional
  depends_on "bat" => :optional
  depends_on "ugrep" => :optional

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

  def caveats
    <<~EOS
      Bluefin CLI bling shell integration has been installed!

      📦 Resources Installed:
      • CLI Logos: #{libexec}/bluefin-logos/
      • Fastfetch Config: #{libexec}/fastfetch/
      • Bling Scripts: #{libexec}/bling/

      🚀 Shell Integration:
      Your installed shells have been automatically configured with bling!
      
      Available tools (optional):
      - eza: Better ls replacement
      - starship: Cross-shell prompt
      - atuin: Shell history search
      - zoxide: Smarter cd command
      - bat: Better cat
      - ugrep: Faster grep

      Install any of these tools to enhance your bling experience:
        brew install eza starship atuin zoxide bat ugrep

      📝 Manual Shell Setup:
      If you need to manually add bling to a shell config, add this line:
      
      Bash/Zsh:
        source #{libexec}/bling/bling.sh
      
      Fish:
        source #{libexec}/bling/bling.fish

      🔗 Documentation: https://docs.projectbluefin.io/command-line
    EOS
  end

  test do
    assert_predicate libexec / "bling" / "bling.sh", :file?
    assert_predicate libexec / "bling" / "bling.fish", :file?
    assert_predicate libexec / "bluefin-logos", :directory?
    assert_predicate libexec / "fastfetch", :directory?
  end
end

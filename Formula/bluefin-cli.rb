class BluefinCli < Formula
  desc "Bluefin CLI logos and fastfetch configuration"
  homepage "https://github.com/ublue-os/packages"
  url "https://github.com/ublue-os/packages/archive/refs/tags/homebrew-2025-10-28-01-29-41.tar.gz"
  version "0.2.6"
  sha256 "2de1cf76b2f76f90a7ef5a93b11e5cf1a24edbffc32f8db72849e75e0b61b92e"
  license "CC-BY-SA"

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

    # Install into share directory for user access
    (share / "bluefin").mkpath
    FileUtils.cp_r(libexec / "bluefin-logos", share / "bluefin/")
    FileUtils.cp_r(libexec / "fastfetch", share / "bluefin/")
  end

  def caveats
    <<~EOS
      Bluefin CLI resources have been installed to #{share}/bluefin/

      For fastfetch configuration, you can symlink or copy the config:
        mkdir -p ~/.config/fastfetch
        cp #{share}/bluefin/fastfetch/fastfetch.jsonc ~/.config/fastfetch/config.jsonc

      CLI logos are available in #{share}/bluefin/bluefin-logos/
    EOS
  end

  test do
    assert_predicate share / "bluefin" / "bluefin-logos", :directory?
    assert_predicate share / "bluefin" / "fastfetch", :directory?
  end
end

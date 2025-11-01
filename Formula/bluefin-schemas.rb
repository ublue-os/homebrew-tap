class BluefinSchemas < Formula
  desc "GNOME DConf schemas and configuration for Bluefin"
  homepage "https://github.com/ublue-os/packages"
  url "https://github.com/ublue-os/packages/archive/refs/tags/homebrew-2025-10-28-01-29-41.tar.gz"
  version "0.2.21"
  sha256 "2de1cf76b2f76f90a7ef5a93b11e5cf1a24edbffc32f8db72849e75e0b61b92e"
  license "CC-BY-SA"

  depends_on "dconf"

  on_linux do
    depends_on "dconf"
  end

  def install
    # GNOME-only resources from packages/bluefin directory
    source_dir = buildpath / "packages/bluefin"

    # dconf settings
    (libexec / "dconf/db/distro.d").mkpath
    (libexec / "dconf/db/distro.d/locks").mkpath

    Dir.glob(source_dir / "schemas/etc/dconf/db/distro.d/*").each do |f|
      next if File.directory?(f)

      (libexec / "dconf/db/distro.d").install f
    end

    Dir.glob(source_dir / "schemas/etc/dconf/db/distro.d/locks/*").each do |f|
      next if File.directory?(f)

      (libexec / "dconf/db/distro.d/locks").install f
    end

    # profile.d settings
    (libexec / "profile.d").mkpath
    Dir.glob(source_dir / "schemas/etc/profile.d/*.sh").each do |f|
      (libexec / "profile.d").install f
    end

    # gnome-initial-setup
    (libexec / "gnome-initial-setup").mkpath
    Dir.glob(source_dir / "schemas/etc/gnome-initial-setup/*").each do |f|
      next if File.directory?(f)

      (libexec / "gnome-initial-setup").install f
    end

    # geoclue configuration
    (libexec / "geoclue/conf.d").mkpath
    geoclue_conf = source_dir / "schemas/etc/geoclue/conf.d/99-beacondb.conf"
    (libexec / "geoclue/conf.d").install geoclue_conf if geoclue_conf.exist?

    # skel configuration (preserve directory structure)
    skel_source = source_dir / "schemas/etc/skel"
    if skel_source.exist?
      Find.find(skel_source) do |path|
        next if File.directory?(path)

        relative_path = Pathname.new(path).relative_path_from(skel_source)
        target_dir = libexec / "skel" / relative_path.dirname
        target_dir.mkpath
        FileUtils.cp(path, target_dir / File.basename(path))
      end
    end

    # xdg configuration
    (libexec / "xdg").mkpath
    Dir.glob(source_dir / "schemas/etc/xdg/*").each do |f|
      next if File.directory?(f)

      (libexec / "xdg").install f
    end

    # glib-2.0 schemas
    (libexec / "glib-2.0/schemas").mkpath
    Dir.glob(source_dir / "schemas/share/glib-2.0/schemas/*").each do |f|
      next if File.directory?(f)

      (libexec / "glib-2.0/schemas").install f
    end

    # applications
    (libexec / "applications").mkpath
    Dir.glob(source_dir / "schemas/share/applications/*.desktop").each do |f|
      next if File.directory?(f)

      (libexec / "applications").install f
    end

    # homebrew brewfiles
    (libexec / "homebrew").mkpath
    Dir.glob(source_dir / "schemas/share/ublue-os/homebrew/*.Brewfile").each do |f|
      next if File.directory?(f)

      (libexec / "homebrew").install f
    end

    # bluefin-bazaar-launcher script
    launcher = source_dir / "schemas/bin/bluefin-bazaar-launcher"
    bin.install launcher if launcher.exist?
  end

  def post_install
    # Compile dconf schemas if dconf is available
    system "dconf", "update" if which("dconf")

    ohai "Bluefin Schemas installation complete!"
    ohai "Note: This is GNOME-only. Please ensure dconf is configured properly."
    ohai "Configuration files have been installed to:"
    ohai "  - #{libexec}/dconf/"
    ohai "  - #{libexec}/glib-2.0/schemas/"
  end

  test do
    # Simple test to verify installation
    assert_predicate libexec / "applications", :directory?
  end
end

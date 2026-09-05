cask "framework-wallpapers" do
  os macos: "darwin", linux: "linux"

  version "2025-12-14"

  on_macos do
    sha256 "e3afcfdbb919d84e02b0f99c2e450514db347bd4e7dd37e9fa23fdb72d321841"

    url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-macos.tar.zstd"
  end
  on_linux do
    if File.exist?("/usr/bin/plasmashell")
      url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-kde.tar.zstd"
      sha256 "2616c84b94bb3e83bf0576bbb260f2a5f98c06674b69e14db335e79d7e3b03a1"
    elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
      url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-gnome.tar.zstd"
      sha256 "8affb9c512d39fc0c665608939815e1eab7062bf1a01c3deab23de367216efc9"
    else
      url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-png.tar.zstd"
      sha256 "2da39f34cb2131861da2adca1d03a6b25b0714b2e7d2686b4d14f7ed8c60e8eb"
    end
  end

  name "framework-wallpapers"
  desc "Wallpapers for Framework laptops"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/framework-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  preflight_steps do
    on_macos do
      mkdir_p "Library/Desktop Pictures/Framework", base: :home
    end

    on_linux do
      mkdir_p ".local/share/backgrounds/framework", base: :home
      mkdir_p ".local/share/wallpapers/framework", base: :home
      mkdir_p ".local/share/gnome-background-properties", base: :home
      inreplace "**/*.xml", "~", "{{home}}", audit_result: false
    end
  end

  postflight_steps do
    on_macos do
      run "ruby", args: [
        "-e",
        <<~RUBY,
          staged_path = ARGV[0]
          home = ARGV[1]
          Dir.glob("\#{staged_path}/*").each do |file|
            target = "\#{home}/Library/Desktop Pictures/Framework/\#{File.basename(file)}"
            FileUtils.ln_sf(file, target)
          end
        RUBY
        "{{staged_path}}",
        "{{home}}",
      ]
    end

    on_linux do
      run "ruby", args: [
        "-e",
        <<~RUBY,
          staged_path = ARGV[0]
          home = ARGV[1]
          destination_dir = "\#{home}/.local/share/backgrounds/framework"
          kde_destination_dir = "\#{home}/.local/share/wallpapers/framework"

          if File.exist?("/usr/bin/plasmashell")
            Dir.glob("\#{staged_path}/*").each do |file|
              target = "\#{kde_destination_dir}/\#{File.basename(file)}"
              FileUtils.ln_sf(file, target)
            end
          elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
            Dir.glob("\#{staged_path}/images/*").each do |file|
              target = "\#{destination_dir}/\#{File.basename(file)}"
              FileUtils.ln_sf(file, target)
            end

            Dir.glob("\#{staged_path}/gnome-background-properties/*").each do |file|
              target = "\#{home}/.local/share/gnome-background-properties/\#{File.basename(file)}"
              FileUtils.ln_sf(file, target)
            end
          else
            Dir.glob("\#{staged_path}/*").each do |file|
              target = "\#{destination_dir}/\#{File.basename(file)}"
              FileUtils.ln_sf(file, target)
            end
          end
        RUBY
        "{{staged_path}}",
        "{{home}}",
      ]
    end
  end

  uninstall_postflight_steps do
    on_macos do
      remove "Library/Desktop Pictures/Framework", base: :home, recursive: true
    end

    on_linux do
      remove ".local/share/backgrounds/framework", base: :home, recursive: true
      remove ".local/share/wallpapers/framework", base: :home, recursive: true
    end
  end

  zap trash: [
    "#{Dir.home}/.local/share/backgrounds/framework",
    "#{Dir.home}/.local/share/gnome-background-properties/framework-*.xml",
    "#{Dir.home}/.local/share/wallpapers/framework",
    "#{Dir.home}/Library/Desktop Pictures/Framework",
  ]

  caveats do
    on_macos do
      <<~EOS
        Wallpapers installed to: #{Dir.home}/Library/Desktop Pictures/Framework
        To use: System Settings > Wallpaper > Add Folder
      EOS
    end
  end
end

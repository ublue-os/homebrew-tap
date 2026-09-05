cask "aurora-wallpapers" do
  version "2026-04-23"
  sha256 "fd029232de0bc45f327c394ecd00023fe52d30b376fe19046660c82f6f8bdcd7"

  url "https://github.com/ublue-os/artwork/releases/download/aurora-v#{version}/aurora-wallpapers.tar.zstd"
  name "aurora-wallpapers"
  desc "Wallpapers for Aurora"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/aurora-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  preflight_steps do
    mkdir_p ".local/share/backgrounds/aurora", base: :home
    mkdir_p ".local/share/gnome-background-properties", base: :home
    inreplace "**/*.xml", "~", "{{home}}", audit_result: false
  end

  postflight_steps do
    run "ruby", args: [
      "-e",
      <<~'RUBY',
        staged_path = ARGV[0]
        home = ARGV[1]
        if File.exist?("/usr/bin/plasmashell")
          Dir.glob("#{staged_path}/kde/*").each do |dir|
            next if dir.include?("gnome-background-properties")

            target = "#{home}/.local/share/backgrounds/aurora/#{File.basename(dir)}"
            FileUtils.ln_sf(dir, target)
          end
        else
          Dir.glob("#{staged_path}/kde/*").each do |dir|
            Dir.glob("#{dir}/contents/images/*").each do |file|
              extension = File.extname(file)
              target = "#{home}/.local/share/backgrounds/aurora/#{File.basename(dir)}#{extension}"
              FileUtils.ln_sf(file, target)
            end

            Dir.glob("#{dir}/gnome-background-properties/*").each do |file|
              target = "#{home}/.local/share/gnome-background-properties/#{File.basename(file)}"
              FileUtils.ln_sf(file, target)
            end
          end
        end
      RUBY
      "{{staged_path}}",
      "{{home}}",
    ]
  end

  uninstall_postflight_steps do
    remove ".local/share/backgrounds/aurora", base: :home, recursive: true
  end

  zap trash: [
    "#{Dir.home}/.local/share/backgrounds/aurora",
    "#{Dir.home}/.local/share/gnome-background-properties/aurora-*.xml",
  ]
end

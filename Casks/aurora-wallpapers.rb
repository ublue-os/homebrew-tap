cask "aurora-wallpapers" do
  version :latest
  sha256 :no_check

  url "https://github.com/projectbluefin/artwork/releases/latest/download/aurora-wallpapers.tar.zstd"
  name "aurora-wallpapers"
  desc "Wallpapers for Aurora"
  homepage "https://github.com/projectbluefin/artwork"

  if ENV["XDG_CURRENT_DESKTOP"] == "KDE"
    Dir.glob("#{staged_path}/kde/*").each do |dir|
      next if File.basename(dir) == "aurora-wallpaper-1"

      if dir.include?("gnome-background-properties")
        next
      end
      artifact dir, target: "#{Dir.home}/.local/share/backgrounds/aurora/#{File.basename(dir)}"
    end
  else
    Dir.glob("#{staged_path}/kde/*").each do |dir|
      next if File.basename(dir) == "aurora-wallpaper-1"

      Dir.glob("#{dir}/contents/images/*").each do |file|
        extension = File.extname(file)
        File.basename(file, extension)
        artifact file, target: "#{Dir.home}/.local/share/backgrounds/aurora/#{File.basename(dir)}#{extension}"
      end

      Dir.glob("#{dir}/gnome-background-properties/*").each do |file|
        artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
      end
    end
  end

  preflight do
    Dir.glob("#{staged_path}/**/*.xml").each do |file|
      contents = File.read(file)
      contents.gsub!("~", Dir.home)
      File.write(file, contents)
    end
  end
end

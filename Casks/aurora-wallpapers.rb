cask "aurora-wallpapers" do
  version :latest
  sha256 :no_check

  url "https://github.com/projectbluefin/artwork/releases/latest/download/aurora-wallpapers.tar.zstd"
  name "aurora-wallpapers"
  desc "Wallpapers for Aurora"
  homepage "https://github.com/projectbluefin/artwork"

  if Env["XDG_CURRENT_DESKTOP"] == "KDE"
    Dir.glob("#{staged_path}/kde/aurora-wallpaper-*").each do |dir|
      next if File.basename(dir) == "aurora-wallpaper-1"

      artifact dir, target: "#{Dir.home}/.local/share/backgrounds/aurora/#{File.basename(dir)}"
    end
  else
    Dir.glob("#{staged_path}/kde/aurora-wallpaper-*").each do |dir|
      next if File.basename(dir) == "aurora-wallpaper-1"

      Dir.glob("#{dir}/contents/images/*").each do |file|
        extension = File.extname(file)
        File.basename(file, extension)
        artifact file, target: "#{Dir.home}/.local/share/backgrounds/aurora/#{File.basename(dir)}.#{extension}"
      end
    end
  end
end

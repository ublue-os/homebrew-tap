cask "bazzite-wallpapers" do
  version :latest
  sha256 :no_check

  url "https://github.com/projectbluefin/artwork/releases/latest/download/bazzite-wallpapers.tar.zstd"
  name "bazzite-wallpapers"
  desc "Wallpapers for Bazzite"
  homepage "https://bazzite.gg/"

  destination_dir = "#{Dir.home}/.local/share/backgrounds/bazzite"

  artifact "images/Convergence_Wallpaper_DX.jxl", target: "#{destination_dir}/Convergence_Wallpaper_DX.jxl"
  artifact "images/Convergence_Wallpaper.png", target: "#{destination_dir}/Convergence_Wallpaper.png"
  artifact "images/Bazzite_Giants.jpg", target: "#{destination_dir}/Bazzite_Giants.jpg"
end

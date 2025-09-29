cask "bazzite-wallpapers" do
  version :latest
  sha256 :no_check

  url "https://github.com/ublue-os/bazzite/tree/main/press_kit/art"
  name "bazzite-wallpapers"
  desc "Wallpapers for Bazzite"
  homepage "https://bazzite.gg/"

  wallpapers = [
    {
      filename: "Convergence_Wallpaper.png",
      url:      "https://raw.githubusercontent.com/ublue-os/bazzite/main/press_kit/art/Convergence_Wallpaper.png",
    },
    {
      filename: "Convergence_Wallpaper_DX.jxl",
      url:      "https://raw.githubusercontent.com/ublue-os/bazzite/main/press_kit/art/Convergence_Wallpaper_DX.jxl",
    },
    {
      filename: "Bazzite_Giants.jpg",
      url:      "https://raw.githubusercontent.com/ublue-os/bazzite/main/press_kit/art/Bazzite_Giants.jpg",
    },
  ]

  destination_dir = "#{Dir.home}/.local/share/backgrounds/bazzite"

  stage_only true

  postflight do
    system "mkdir", "-p", destination_dir

    wallpapers.each do |wallpaper|
      ohai "Downloading #{wallpaper[:filename]} to #{destination_dir}"
      system "curl", "-L", "-o", "#{destination_dir}/#{wallpaper[:filename]}", wallpaper[:url]
    end
  end
end

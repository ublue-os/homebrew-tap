class HeicToDynamicGnomeWallpaper < Formula
  desc "Convert macOS HEIC dynamic wallpapers to GNOME dynamic wallpapers"
  homepage "https://github.com/fia0/heic-to-dynamic-gnome-wallpaper"
  url "https://github.com/fia0/heic-to-dynamic-gnome-wallpaper/archive/refs/tags/v0.1.6.tar.gz"
  sha256 "4a314af6db981887a4a848969e951f6a2cd9a59c5d15367ebf6261f08c45b0d7"
  license "GPL-3.0-only"

  livecheck do
    url "https://github.com/fia0/heic-to-dynamic-gnome-wallpaper/releases"
    strategy :github_releases
  end

  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  depends_on "libheif"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system "#{bin}/heic-to-dynamic-gnome-wallpaper", "--help"
  end
end

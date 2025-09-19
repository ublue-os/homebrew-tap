cask "jetbrains-toolbox-linux" do
  version "2.9.0.56191"
  sha256 "927ccdbe1791d36311250a76721bd05849f996f52068f9eb3c7436f0018ab6c0"

  url "https://download.jetbrains.com/toolbox/jetbrains-toolbox-#{version}.tar.gz"
  name "JetBrains Toolbox"
  desc "JetBrains tools manager"
  homepage "https://www.jetbrains.com/toolbox-app/"

  livecheck do
    url "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"
    strategy :json do |json|
      json["TBA"]&.map { |release| release["build"] }
    end
  end

  auto_updates true

  # Correct binary path inside the tarball
  binary "jetbrains-toolbox-#{version}/bin/jetbrains-toolbox"
  artifact "jetbrains-toolbox-#{version}/jetbrains-toolbox.desktop",
           target: "#{Dir.home}/.local/share/applications/jetbrains-toolbox.desktop"

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    # We need this file to start, but Jetbrains Toolbox will overwrite it on its first run with a proper one
    # It will also extract the icon from somewhere, but it doesn't exist until first run, so we just point to where it
    # should be, and it will get fixed on first run
    File.write("#{staged_path}/jetbrains-toolbox-#{version}/jetbrains-toolbox.desktop", <<~EOS)
      [Desktop Entry]
      Icon=#{staged_path}/jetbrains-toolbox-#{version}/bin/toolbox.svg
      Exec=#{HOMEBREW_PREFIX}/bin/jetbrains-toolbox %u
      Version=1.0
      Type=Application
      Categories=Development
      Name=JetBrains Toolbox
      StartupWMClass=jetbrains-toolbox
      Terminal=false
      MimeType=x-scheme-handler/jetbrains;
      X-GNOME-Autostart-enabled=true
      StartupNotify=false
      X-GNOME-Autostart-Delay=10
      X-MATE-Autostart-Delay=10
      X-KDE-autostart-after=panel
    EOS
  end

  zap trash: "~/.config/JetBrains/ToolboxApp"
end

cask "jetbrains-toolbox-linux" do
  version "2.8.1.52155"
  sha256 "23fc2af0aed0d59a894399e651eec942c7711f89f5d3b6d548ef6ba3358f01e5"

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
  binary "#{staged_path}/jetbrains-toolbox-#{version}/bin/jetbrains-toolbox"

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    File.write("#{staged_path}/jetbrains-toolbox-#{version}/jetbrains-toolbox.desktop", <<~EOS)
      [Desktop Entry]
      Name=JetBrains Toolbox
      Comment=JetBrains tools manager
      GenericName=Development Tools Manager
      Exec=#{HOMEBREW_PREFIX}/bin/jetbrains-toolbox
      Icon=jetbrains-toolbox
      Type=Application
      StartupNotify=false
      StartupWMClass=JetBrains Toolbox
      Categories=Development;IDE;
      Keywords=jetbrains;toolbox;ide;
    EOS
  end

  zap trash: "~/.config/JetBrains/ToolboxApp"
end

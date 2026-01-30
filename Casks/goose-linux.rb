cask "goose-linux" do
  version "1.22.0"
  sha256 "5741ff7a1eef4879a11f5da1a5470b552588dc79035842cd5258ed01a8384399"

  url "https://github.com/block/goose/releases/download/v#{version}/Goose-#{version}-1.x86_64.rpm",
      verified: "github.com/block/goose/"
  name "Goose"
  desc "Open source, extensible AI agent that goes beyond code suggestions"
  homepage "https://block.github.io/goose/"

  livecheck do
    url "https://github.com/block/goose/releases"
    regex(%r{/v?(\d+(?:\.\d+)+)/Goose[._-]v?\d+(?:\.\d+)+-\d+\.x86_64\.rpm}i)
    strategy :github_releases do |json, regex|
      json.map do |release|
        next if release["draft"] || release["prerelease"]

        release["assets"]&.map do |asset|
          match = asset["browser_download_url"]&.match(regex)
          next if match.blank?

          match[1]
        end
      end.flatten
    end
  end

  depends_on formula: "rpm2cpio"

  binary "usr/lib/Goose/Goose", target: "goose-desktop"
  artifact "Goose.desktop",
           target: "#{Dir.home}/.local/share/applications/Goose.desktop"
  artifact "usr/share/pixmaps/Goose.png",
           target: "#{Dir.home}/.local/share/icons/Goose.png"

  preflight do
    system "sh", "-c", "rpm2cpio '#{staged_path}/Goose-#{version}-1.x86_64.rpm' | cpio -idm --quiet",
           chdir: staged_path

    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"

    File.write("#{staged_path}/Goose.desktop", <<~EOS)
      [Desktop Entry]
      Name=Goose
      Comment=Open source, extensible AI agent that goes beyond code suggestions
      Exec=#{HOMEBREW_PREFIX}/bin/goose-desktop %U
      Icon=#{Dir.home}/.local/share/icons/Goose.png
      Terminal=false
      Type=Application
      Categories=Development;
      MimeType=x-scheme-handler/goose;
      StartupWMClass=Goose
    EOS
  end

  zap trash: [
    "~/.config/Goose",
    "~/.local/share/Goose",
  ]
end

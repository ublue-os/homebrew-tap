cask "goose-linux" do
  version "1.59.0"
  sha256 "4f4e65a700cd053583205ac36fa21162a8f59950fa8d63b213c1c79c3b3aa4a2"

  url "https://github.com/block/goose/releases/download/v#{version}/Goose-#{version}-1.x86_64.rpm"
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

  preflight_steps do
    run "sh", args: ["-c", "rpm2cpio '{{staged_path}}/Goose-#{version}-1.x86_64.rpm' | cpio -idm --quiet"], chdir: "."

    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    write_file "Goose.desktop", <<~EOS
      [Desktop Entry]
      Name=Goose
      Comment=Open source, extensible AI agent that goes beyond code suggestions
      Exec={{HOMEBREW_PREFIX}}/bin/goose-desktop %U
      Icon=Goose
      Terminal=false
      Type=Application
      Categories=Development;
      MimeType=x-scheme-handler/goose;
      StartupWMClass=goose
    EOS
  end

  zap trash: [
    "~/.config/Goose",
    "~/.local/share/Goose",
  ]
end

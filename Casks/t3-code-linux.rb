cask "t3-code-linux" do
  version "0.0.33"
  sha256 "415c8648f43c3d22d572f27f2c50fdc8c310ea7fcde9537b903e1e2f1c8775a1"

  url "https://github.com/pingdotgg/t3code/releases/download/v#{version}/T3-Code-#{version}-x86_64.AppImage"
  name "T3 Code"
  desc "Desktop control surface for local coding agents"
  homepage "https://github.com/pingdotgg/t3code"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on formula: "squashfs"

  binary "squashfs-root/AppRun", target: "t3code"
  artifact "squashfs-root/usr/share/icons/hicolor/512x512/apps/t3code.png",
           target: "#{Dir.home}/.local/share/icons/t3code.png"
  artifact "squashfs-root/t3code.desktop",
           target: "#{Dir.home}/.local/share/applications/t3code.desktop"

  preflight do
    appimage_path = "#{staged_path}/T3-Code-#{version}-x86_64.AppImage"
    system "chmod", "+x", appimage_path
    system appimage_path, "--appimage-extract", chdir: staged_path
    FileUtils.rm appimage_path

    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"

    desktop_path = "#{staged_path}/squashfs-root/t3code.desktop"
    desktop_content = File.read(desktop_path)
    # AppRun adds --no-sandbox itself when unprivileged user namespaces are unavailable.
    desktop_content.gsub!(/^Exec=.*/, "Exec=#{HOMEBREW_PREFIX}/bin/t3code %U")
    File.write(desktop_path, desktop_content)
  end
end

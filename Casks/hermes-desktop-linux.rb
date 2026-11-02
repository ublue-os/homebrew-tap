cask "hermes-desktop-linux" do
  version "0.22.5"
  # Self-hosted artifact, built from a clean checkout at the release tag with
  #   python -m scripts.bundles.desktop --tag=vX.Y.Z --variant=light
  # (upstream light desktop variant: no bundled agent runtime; on Linux it is
  # stamped updateMechanism: external, so brew owns updates). Pin the real
  # sha256 here once the artifact is uploaded to the tap release.
  sha256 :no_check

  url "https://github.com/tunix/homebrew-tap/releases/download/hermes-desktop-v#{version}/HermesLight-#{version}-linux-x64.AppImage"
  name "Hermes Light"
  desc "Remote-only desktop client for Hermes Agent"
  homepage "https://hermes-agent.nousresearch.com/desktop"

  livecheck do
    url "https://api.github.com/repos/NousResearch/hermes-agent/releases/latest"
    strategy :json do |json|
      json["tag_name"]&.delete_prefix("v")
    end
  end

  depends_on arch: :x86_64

  binary "hermes-desktop.sh", target: "hermes-desktop"

  preflight do
    # Upstream light AppImage: Electron shell + chat UI, no bundled agent
    # runtime. Extracted at install time so FUSE is not needed at run time.
    appimage = "#{staged_path}/HermesLight-#{version}-linux-x64.AppImage"
    system "chmod", "+x", appimage
    system appimage, "--appimage-extract", chdir: staged_path

    # Wrapper the menu entry points at; survives cask upgrades because it is
    # re-linked into HOMEBREW_PREFIX/bin on every install.
    shim = "#{staged_path}/hermes-desktop.sh"
    File.write(shim, <<~EOS)
      #!/bin/bash
      # Hermes Light (homebrew cask wrapper) — remote-only desktop client for
      # Hermes Agent. Preset the backend with HERMES_DESKTOP_REMOTE_URL, or
      # configure it in-app on first launch (Settings -> Gateways).
      exec "$(dirname "$(readlink -f "$0")")/squashfs-root/AppRun" "$@"
    EOS
    FileUtils.chmod "+x", shim

    icon = Dir["#{staged_path}/squashfs-root/**/*.png"].max_by { |f| File.size(f) }
    if icon
      icon_dir = "#{Dir.home}/.local/share/icons/hicolor/512x512/apps"
      FileUtils.mkdir_p icon_dir
      FileUtils.cp icon, "#{icon_dir}/hermes-light.png"
    end

    # Keep the menu entry pointing at the brew wrapper instead of the
    # versioned Caskroom path so it survives upgrades.
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    shipped = Dir["#{staged_path}/squashfs-root/*.desktop"].first
    entry = if shipped
      text = File.read(shipped)
      text = text.gsub(/^Exec=.*/, "Exec=#{HOMEBREW_PREFIX}/bin/hermes-desktop")
      text = text.gsub(/^Icon=.*/, "Icon=hermes-light")
      text
    else
      <<~DESKTOP
        [Desktop Entry]
        Type=Application
        Name=Hermes Light
        Comment=Remote-only desktop client for Hermes Agent
        Exec=#{HOMEBREW_PREFIX}/bin/hermes-desktop
        Icon=hermes-light
        Terminal=false
        Categories=Development;Network;
      DESKTOP
    end
    File.write("#{staged_path}/hermes-light.desktop", entry)
  end

  artifact "hermes-light.desktop",
           target: "#{Dir.home}/.local/share/applications/hermes-light.desktop"

  # Client-only cask: never touch ~/.hermes — that home belongs to the agent,
  # which may legitimately live on this machine for CLI users.
  zap trash: [
    "~/.local/share/icons/hicolor/512x512/apps/hermes-light.png",
  ]
end

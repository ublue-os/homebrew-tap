cask "hermes-desktop-linux" do
  version "0.22.5"
  # Self-hosted artifact, built from a clean checkout at the release tag with
  #   python -m scripts.bundles.desktop --tag=vX.Y.Z --variant=light
  # (upstream light desktop variant: no bundled agent runtime; on Linux it is
  # stamped updateMechanism: external, so brew owns updates).
  sha256 "598f62c95e6954eebfff3bd9ddc6ea02d394c657a90de5b36a4c7aaf69cbcbd9"

  url "https://github.com/tunix/homebrew-tap/releases/download/hermes-desktop-v#{version}/HermesLight-#{version}-linux-x86_64.AppImage"
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

  preflight_steps do
    # Upstream light AppImage: Electron shell + chat UI, no bundled agent
    # runtime. Extracted at install time so FUSE is not needed at run time.
    write_file "hermes-install.sh", <<~EOS
      set -euo pipefail

      appimage="HermesLight-#{version}-linux-x86_64.AppImage"
      chmod +x "$appimage"
      "./$appimage" --appimage-extract

      # Wrapper the menu entry points at; survives cask upgrades because it
      # is re-linked into HOMEBREW_PREFIX/bin on every install.
      cat > hermes-desktop.sh <<'SH'
      #!/bin/bash
      # Hermes Agent (remote client; homebrew cask wrapper). Preset the
      # backend with HERMES_DESKTOP_REMOTE_URL, or
      # configure it in-app on first launch (Settings -> Gateways).
      exec "$(dirname "$(readlink -f "$0")")/squashfs-root/AppRun" "$@"
      SH
      chmod +x hermes-desktop.sh

      # Point the shipped menu entry at the brew wrapper and a stable icon
      # name instead of the versioned Caskroom path.
      desktop="$(ls -1 squashfs-root/*.desktop 2>/dev/null | head -n1 || true)"
      if [ -n "$desktop" ]; then
        sed -i "s|^Exec=.*|Exec={{HOMEBREW_PREFIX}}/bin/hermes-desktop|" "$desktop"
        sed -i "s|^Icon=.*|Icon=hermes-light|" "$desktop"
        # Present the menu entry as "Hermes Agent" (the upstream build's
        # internal display name stays "Hermes Light"); Exec/Icon/StartupWMClass
        # are kept so GNOME still maps the running window to this entry.
        sed -i "/^Name\\[/d" "$desktop"
        sed -i "s|^Name=.*|Name=Hermes Agent|" "$desktop"
        cp "$desktop" hermes-light.desktop
      else
        printf '%s\n' \
          "[Desktop Entry]" "Type=Application" "Name=Hermes Agent" \
          "Comment=Remote desktop client for Hermes Agent" \
          "Exec={{HOMEBREW_PREFIX}}/bin/hermes-desktop" "Icon=hermes-light" \
          "Terminal=false" "Categories=Development;Network;" > hermes-light.desktop
      fi

      icon="$(find squashfs-root -type f -name '*.png' -printf '%s %p\n' 2>/dev/null | sort -rn | head -n1 | cut -d' ' -f2-)"
      if [ -n "$icon" ]; then
        cp "$icon" hermes-light.png
      fi
    EOS
    run "bash", args: ["hermes-install.sh"], chdir: "."
  end

  postflight_steps do
    mkdir_p ".local/share/applications", base: :home
    if_path_exists "hermes-light.desktop" do
      copy "hermes-light.desktop", ".local/share/applications/hermes-light.desktop", target_base: :home
    end

    mkdir_p ".local/share/icons/hicolor/512x512/apps", base: :home
    if_path_exists "hermes-light.png" do
      copy "hermes-light.png", ".local/share/icons/hicolor/512x512/apps/hermes-light.png", target_base: :home
    end
  end

  uninstall_preflight_steps do
    # postflight_steps-installed menu files are not tracked by artifact links;
    # remove them so a plain uninstall leaves no stale launcher entry behind.
    if_path_exists ".local/share/applications/hermes-light.desktop", base: :home do
      remove ".local/share/applications/hermes-light.desktop", base: :home
    end
    if_path_exists ".local/share/icons/hicolor/512x512/apps/hermes-light.png", base: :home do
      remove ".local/share/icons/hicolor/512x512/apps/hermes-light.png", base: :home
    end
  end

  # Client-only cask: never touch ~/.hermes — that home belongs to the agent,
  # which may legitimately live on this machine for CLI users.
  zap trash: [
    "~/.local/share/applications/hermes-light.desktop",
    "~/.local/share/icons/hicolor/512x512/apps/hermes-light.png",
  ]
end

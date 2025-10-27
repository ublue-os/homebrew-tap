# Positron app
# =====================================================================================
# The Data Science IDE: Positron unifies exploration and production work in one free, 
# AI-powered environment, empowering the full spectrum of data science in Python and R.
# -------------------------------------------------------------------------------------
# Resources:
# - https://positron.posit.co/
# - https://github.com/posit-dev/positron
# -------------------------------------------------------------------------------------
# Tested and compatible with:
# - bluefin-gdx:lts (x64)
# - HomeBrew
# Details:
# - ostree-image-signed:docker://ghcr.io/ublue-os/bluefin-gdx:lts
# - Digest: sha256:51f40eeac00183ee2f75c31fa2f4c8dd6b3e2f6f03d6ab1468429e1d0f675723
# - Version: stream10.1 (2025-10-06T17:29:22Z)
# - ublue-brew.x86_64 0.1.11-1.el10
# -------------------------------------------------------------------------------------
# Usage:
# brew install --cask positron-linux
# brew uninstall --cask positron-linux
# -------------------------------------------------------------------------------------
require 'fileutils'

cask "positron-linux" do
  arch arm: "arm64", intel: "x86_64"
  os linux: "linux"

  version "2025.10.1-4"
  sha256 arm64_linux:  "81cafc1683660bea2348da68aac442515c23aae213a92d875c6756ffc8ee6436",
         x86_64_linux: "4278d24d4a0c083a11493e35471955002d2c16316526e7f21d30bf3d8a3d8a91"

  url "https://cdn.posit.co/positron/releases/rpm/#{arch}/Positron-#{version}-#{arch == 'x86_64' ? 'x64' : 'arm64'}.rpm"
  name "Positron"
  desc "Interactive data science and development environment by Posit"
  homepage "https://positron.posit.co"

  livecheck do
    url "https://github.com/posit-dev/positron"
    regex(/tag\/v?(\d+\.\d+\.\d+-\d+)/i)
    strategy :github_latest
  end

  # Do not directly use the extracted desktop files: incorrect Exec path
  artifact "positron.desktop",
           target: "#{Dir.home}/.local/share/applications/positron.desktop"
  artifact "positron-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/positron-url-handler.desktop"

  preflight do
    FileUtils.mkdir_p("#{Dir.home}/.local/share/applications")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/icons")

    # Write desktop files, code mostly copied from original. 
    # Adjusted Exec paths and icon names. Added positron to Keywords
    File.write("#{staged_path}/positron.desktop", <<~EOS)
      [Desktop Entry]
      Name=Positron
      Comment=The next generation IDE for data science
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/positron %F
      Icon=positron
      Type=Application
      StartupNotify=false
      StartupWMClass=Positron
      Categories=TextEditor;Development;IDE;
      MimeType=application/x-positron-workspace;
      Actions=new-empty-window;
      Keywords=vscode;positron;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Name[cs]=Nové prázdné okno
      Name[de]=Neues leeres Fenster
      Name[es]=Nueva ventana vacía
      Name[fr]=Nouvelle fenêtre vide
      Name[it]=Nuova finestra vuota
      Name[ja]=新しい空のウィンドウ
      Name[ko]=새 빈 창
      Name[ru]=Новое пустое окно
      Name[zh_CN]=新建空窗口
      Name[zh_TW]=開新空視窗
      Exec=#{HOMEBREW_PREFIX}/bin/positron --new-window %F
      Icon=positron
    EOS
    File.write("#{staged_path}/positron-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=Positron - URL Handler
      Comment=The next generation IDE for data science
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/positron --open-url %U
      Icon=positron
      Type=Application
      NoDisplay=true
      StartupNotify=true
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/positron;
      Keywords=vscode;positron;
    EOS

    # Create extraction directory inside staged_path
    extracted_dir = "#{staged_path}/Positron-#{version}-#{arch}"
    FileUtils.mkdir_p extracted_dir

    # Determine RPM filename (x86_64 uses 'x64.rpm', arm64 uses 'arm64.rpm')
    rpm_filename = arch == "x86_64" ? "x64.rpm" : "arm64.rpm"
    rpm_path = "#{staged_path}/Positron-#{version}-#{rpm_filename}"

    # Temporary extraction files
    temp_cpio = "#{staged_path}/temp.cpio"
    temp_stderr = "#{staged_path}/temp.stderr"

    # Extract RPM into extracted_dir (not staged_path)
    system_command "/bin/sh", args: ["-c", "rpm2cpio '#{rpm_path}' > '#{temp_cpio}' 2> '#{temp_stderr}'"]
    raise "Failed RPM extraction" unless $?.success?

    # Change to extracted_dir before extracting cpio
    Dir.chdir(extracted_dir) do
      system_command "/bin/sh", args: ["-c", "cat '#{temp_cpio}' | cpio -idmv 2> '#{temp_stderr}'"]
      raise "Failed cpio extraction" unless $?.success?
    end

    FileUtils.rm_rf [temp_cpio, temp_stderr]

    # Copy entire /usr/share/positron and icon to cask's staging directory
    FileUtils.cp_r(Dir.glob("#{extracted_dir}/usr/share/positron/*"), staged_path)
    FileUtils.cp_r(Dir.glob("#{extracted_dir}/usr/share/pixmaps/co.posit.positron.png"), staged_path)

    # Clean up temporary files and RPM
    FileUtils.rm_rf extracted_dir
    FileUtils.rm_f rpm_path
  end

  # Binary must point the actual binary
  binary "#{staged_path}/bin/positron"
  # relative path for completions and artifacts (no staged_path)
  bash_completion "resources/completions/bash/positron"
  zsh_completion  "resources/completions/zsh/_positron"
  artifact "co.posit.positron.png",
           target: "#{Dir.home}/.local/share/icons/positron.png"

  # Cleanup  
  zap trash: [
    File.join(Dir.home, ".config/positron"),
    File.join(Dir.home, ".cache/positron")
  ]
end


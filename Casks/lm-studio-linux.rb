cask "lm-studio-linux" do
  version "0.3.26,6"
  sha256 "50a768a70fec32e5d8e3ad0a03d3a3f1c90035d143b76540a44b126751a1d56a"

  url "https://installers.lmstudio.ai/linux/x64/#{version.tr(",", "-")}/LM-Studio-#{version.tr(",", "-")}-x64.AppImage"
  name "LM Studio"
  desc "Discover, download, and run local LLMs"
  homepage "https://lmstudio.ai/"

  auto_updates true
  depends_on formula: "squashfs"

  binary "#{staged_path}/lm-studio-#{version.tr(",", "-")}/contents/AppRun", target: "lm-studio"

  preflight do
    # Extract AppImage contents - change to staged_path first so squashfs-root is created there
    appimage_path = "#{staged_path}/LM-Studio-#{version.tr(",", "-")}-x64.AppImage"
    system "chmod", "+x", appimage_path

    system "cd '#{staged_path}' && '#{appimage_path}' --appimage-extract"

    # Create versioned directory structure
    target_dir = "#{staged_path}/lm-studio-#{version.tr(",", "-")}"
    FileUtils.mkdir_p target_dir
    FileUtils.mv "#{staged_path}/squashfs-root", "#{target_dir}/contents"

    # Remove the original AppImage to save space
    FileUtils.rm appimage_path

    # Clean up any stray squashfs-root directories
    ["squashfs-root", "#{Dir.pwd}/squashfs-root"].each do |stray_path|
      FileUtils.rm_r(stray_path) if File.exist?(stray_path)
    end

    # Set up desktop integration
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    if File.exist?("#{target_dir}/contents/lm-studio.desktop")
      # Use bundled desktop file if available
      desktop_content = File.read("#{target_dir}/contents/lm-studio.desktop")
      desktop_content.gsub!(/^Exec=.*/, "Exec=#{HOMEBREW_PREFIX}/bin/lm-studio")
      File.write("#{Dir.home}/.local/share/applications/lm-studio.desktop", desktop_content)
    else
      # Fallback to custom desktop file
      File.write("#{Dir.home}/.local/share/applications/lm-studio.desktop", <<~EOS)
        [Desktop Entry]
        Name=LM Studio
        Comment=Discover, download, and run local LLMs
        GenericName=LLM Manager
        Exec=#{HOMEBREW_PREFIX}/bin/lm-studio
        Icon=lm-studio
        Type=Application
        StartupNotify=false
        StartupWMClass=LM Studio
        Categories=Development;AI;
        Keywords=llm;ai;local;model;
      EOS
    end
  end

  zap trash: [
    "~/.config/LMStudio",
    "~/.local/share/applications/lm-studio.desktop",
  ]
end

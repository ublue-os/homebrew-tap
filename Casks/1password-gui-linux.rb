module Utils
  def self.alternate_arch(arch)
    case arch
    when "aarch64"
      "arm64"
    when "x86_64"
      "x64"
    end
  end

  def self.replace_path_in_file(file_path, old_text, new_text)
    text = File.read(file_path)
    new_contents = text.gsub(old_text, new_text)
    File.open(file_path, "w") { |file| file.puts new_contents }
  end
end

cask "1password-gui-linux" do
  arch intel: "x86_64", arm: "aarch64"
  os linux: "linux"

  version "8.11.8"
  sha256 :no_check

  url "https://downloads.1password.com/#{os}/tar/stable/#{arch}/1password-latest.tar.gz"
  name "1Password"
  desc "Password manager that keeps all passwords secure behind one password"
  homepage "https://1password.com/"

  livecheck do
    url "https://releases.1password.com/linux/stable/index.xml"
    regex(/v?(\d+(?:\.\d+)+)/i)
    strategy :xml do |xml, regex|
      xml.get_elements("rss//channel//item//link").map { |item| item.text[regex, 1] }
    end
  end

  auto_updates true

  binary "1password-#{version}.#{Utils.alternate_arch(arch)}/1password",
         target: "1password"
  binary "1password-#{version}.#{Utils.alternate_arch(arch)}/op-ssh-sign",
         target: "op-ssh-sign"
  artifact "1password-#{version}.#{Utils.alternate_arch(arch)}/resources/1password.desktop",
           target: "#{Dir.home}/.local/share/applications/1password.desktop"
  artifact "1password-#{version}.#{Utils.alternate_arch(arch)}/resources/icons/hicolor/256x256/apps/1password.png",
           target: "#{Dir.home}/.local/share/icons/1password.png"

  preflight do
    Utils.replace_path_in_file("#{staged_path}/1password-#{version}.#{Utils.alternate_arch(arch)}/resources/1password.desktop",
                               "Exec=/opt/1Password/1password",
                               "Exec=#{HOMEBREW_PREFIX}/bin/1password")
  end

  caveats "You will need to run `sudo install -Dm0644 #{staged_path}/1password-#{version}.#{Utils.alternate_arch(arch)}/com.1password.1Password.policy -t /etc/polkit-1/actions/;` to enable unlocking the 1Password app via your system password."

  zap trash: [
    "~/.cache/1password",
    "~/.config/1Password",
    "~/.local/share/1password",
    "~/.local/share/applications/1password.desktop",
    "~/.local/share/icons/1password.png",
    "~/.local/share/keyrings/1password.keyring",
  ]
end

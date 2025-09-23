class Asusctl < Formula
  desc "Control daemon, CLI tools for interacting with ASUS ROG laptops"
  homepage "https://gitlab.com/asus-linux/asusctl"
  url "https://gitlab.com/asus-linux/asusctl.git", tag: "6.1.12", revision: "685345d6567bc366e93bbc3d7321f9d9a719a7ed"
  license "MPL-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/ublue-os/homebrew-tap/releases/download/asusctl-6.1.12"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "ab7476fadc21a33dda014a766135d47d3b97c33d126e817591f465949471f842"
  end

  depends_on "llvm" => :build
  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  depends_on "libgudev"
  depends_on :linux

  def install
    ENV.prepend_path "PKG_CONFIG_PATH", Formula["libgudev"].opt_lib/"pkgconfig"
    ENV.prepend_path "PKG_CONFIG_PATH", Formula["systemd"].opt_lib/"pkgconfig"

    # Set up libclang for bindgen
    ENV["LIBCLANG_PATH"] = Formula["llvm"].opt_lib.to_s

    # Install specific workspace members
    system "cargo", "install", "--path", "asusctl", "--root", prefix, "--locked"
    system "cargo", "install", "--path", "asusd", "--root", prefix, "--locked"
    system "cargo", "install", "--path", "asusd-user", "--root", prefix, "--locked"

    # Install data files
    (share/"rog-gui"/layouts).install "rog-aura/data/layouts/*.ron"
    (lib/"udev"/"rules.d").install "data/99-asusd.rules"
    (share/"asusd").install "rog-aura/data/aura_support.ron"
    (share/"dbus-1"/"system.d").install "data/asusd.conf"

    # Install icons
    Dir["data/icons/*.png"].each do |icon|
      (share/"icons"/"hicolor"/"512x512"/"apps").install icon
    end

    Dir["data/icons/scalable/*.svg"].each do |icon|
      (share/"icons"/"hicolor"/"scalable"/"status").install icon
    end

    # Install upstream systemd service file with corrected path
    (config/"systemd"/"user").mkpath
    (config/"systemd"/"system").mkpath

    # Copy and modify the upstream service file if it exists
    if File.exist?("data/asusd-user.service")
      service_content = File.read("data/asusd-user.service")
      # Replace the path with Homebrew's path
      service_content.gsub!("/usr/bin/asusd-user", "#{opt_bin}/asusd-user")
      (etc/"systemd"/"user"/"asusd-user.service").write(service_content)
    end
    if File.exist?("data/asusd.service")
      service_content = File.read("data/asusd.service")
      # Replace the path with Homebrew's path
      service_content.gsub!("/usr/bin/asusd-user", "#{opt_bin}/asusd")
      (etc/"systemd"/"system"/"asusd.service").write(service_content)
    end
  end

  service do
    name linux: "asusd-user"
  end

  service do
    name linux: "asusd"
  end

  def caveats
    <<~EOS
      To install the user service:
        ln -sf #{etc}/systemd/user/asusd-user.service ~/.config/systemd/user/
        systemctl --user daemon-reload
        systemctl --user enable asusd-user.service
        systemctl --user start asusd-user.service

      To install the system service:
        ln -sf #{etc}/systemd/system/asusd.service /etc/systemd/system/
        systemctl daemon-reload
        systemctl enable asusd.service
        systemctl start asusd.service
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/asusctl --version")
  end
end

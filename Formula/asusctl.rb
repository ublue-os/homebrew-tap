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
    sha256 cellar: :any_skip_relocation, x86_64_linux: "60158bd6f96dfa01fb096d13f606b56050e1e0db862c1d354648a84dfa54b2bc"
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
    Dir["rog-aura/data/layouts/*.ron"].each do |layout|
      (share/"rog-gui"/"layouts").install layout
    end
    (lib/"udev"/"rules.d").install "data/asusd.rules" => "99-asusd.rules"
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
    (etc/"systemd"/"user").mkpath
    (etc/"systemd"/"system").mkpath

    # Copy and modify the upstream user service file
    service_content = File.read("data/asusd-user.service")
    service_content.gsub!("/usr/bin/asusd-user", "#{bin}/asusd-user")
    (etc/"systemd"/"user"/"asusd-user.service").write(service_content)

    service_content = File.read("data/asusd.service")
    service_content.gsub!("/usr/bin/asusd", "#{bin}/asusd")

    # Add the [Install] section if it doesn't exist
    service_content += "\n[Install]\nWantedBy=multi-user.target\n" unless service_content.include?("[Install]")

    (etc/"systemd"/"system"/"asusd.service").write(service_content)
  end

  service do
    name linux: "asusd-user"
  end

  service do
    name linux: "asusd"
  end

  def caveats
    <<~EOS
      asusctl requires both system and user services to function properly.
      The system service (asusd) must be running before the user service (asusd-user) will work.

      To install the system service:
        sudo cp #{etc}/systemd/system/asusd.service /etc/systemd/system/
        sudo semanage fcontext -a -t systemd_unit_file_t #{etc}/systemd/system/asusd.service
        sudo semanage fcontext -a -t bin_t #{etc}/bin/asusd
        sudo restorecon -vvRF/etc/systemd/system/asusd.service
        sudo restorecon -vvRF #{bin}/asusd
        sudo systemctl daemon-reload
        sudo systemctl enable asusd.service
        sudo systemctl start asusd.service

      To install the user service:
        ln -sf #{etc}/systemd/user/asusd-user.service ~/.config/systemd/user/
        systemctl --user daemon-reload
        systemctl --user enable asusd-user.service
        systemctl --user start asusd-user.service

      Verify installation:
        sudo systemctl status asusd.service
        systemctl --user status asusd-user.service
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/asusctl --version")
  end
end

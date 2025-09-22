class Asusctl < Formula
  desc "Control daemon, CLI tools for interacting with ASUS ROG laptops"
  homepage "https://gitlab.com/asus-linux/asusctl"
  url "https://gitlab.com/asus-linux/asusctl/-/archive/6.1.12/asusctl-6.1.12.tar.gz"
  sha256 "8b0f2851a48c64aa827dc4a771326f89478f443ef23e6208429d77b5871d04bf"
  license "MPL-2.0"

  bottle do
    root_url "https://github.com/ublue-os/homebrew-tap/releases/download/asusctl-6.1.12"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "a3ed5168d651169836b286334951b48eb3335cf972caa7be27df63090794ef54"
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
  end

  def caveats
    <<~EOS
      asusctl requires Linux kernel modules (asus-wmi, asus-armoury). If you see a feature is missing you
      either need a patched kernel or latest release.

      To enable the user service:
        systemctl --user enable asusd-user.service
        systemctl --user start asusd-user.service

      The service will automatically start on login after enabling.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/asusctl --version")
  end
end

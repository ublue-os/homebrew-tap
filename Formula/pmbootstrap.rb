class Pmbootstrap < Formula
  include Language::Python::Virtualenv

  desc "Sophisticated chroot / build / flash tool to develop and install postmarketOS"
  homepage "https://gitlab.postmarketos.org/postmarketOS/pmbootstrap"
  url "https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git", tag: "3.10.2", revision: "021ed2f5e15fa70f1543997fc76c7e9f8b8c8e68"

  license "GPL-3.0-only"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1] }
    end
  end

  bottle do
    root_url "https://github.com/ublue-os/homebrew-tap/releases/download/pmbootstrap-3.10.2"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "708d9f0d7c3ea4976688f5b3997eae32c6c30bafb1e46c3914a2f74c52be5f46"
  end

  depends_on linux: :any
  depends_on "python@3.14"

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pmbootstrap --version")
  end
end

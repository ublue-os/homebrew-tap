class Pmbootstrap < Formula
  include Language::Python::Virtualenv

  desc "Sophisticated chroot / build / flash tool to develop and install postmarketOS"
  homepage "https://gitlab.postmarketos.org/postmarketOS/pmbootstrap"
  url "https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git", tag: "3.9.0", revision: "888d8b4a2733af411e81d3c36b2a5945ed1e3467"

  license "GPL-3.0-only"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1] }
    end
  end

  bottle do
    root_url "https://github.com/ublue-os/homebrew-tap/releases/download/pmbootstrap-3.9.0"
    rebuild 2
    sha256 x86_64_linux: "a2f2010a23f49ad2de460eb4391bb57df2e57efce0478baddd23f4f541ef903e"
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

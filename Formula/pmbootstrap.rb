class Pmbootstrap < Formula
  include Language::Python::Virtualenv

  desc "Sophisticated chroot / build / flash tool to develop and install postmarketOS"
  homepage "https://gitlab.postmarketos.org/postmarketOS/pmbootstrap"
  url "https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git", tag: "3.10.3", revision: "845cda033ab534f8350f71baea9226603f1c5693"

  license "GPL-3.0-only"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1] }
    end
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

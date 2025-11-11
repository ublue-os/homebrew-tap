class Pmbootstrap < Formula
  include Language::Python::Virtualenv

  desc "Sophisticated chroot / build / flash tool to develop and install postmarketOS'"
  homepage "https://gitlab.postmarketos.org/postmarketOS/pmbootstrap"
  url "https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git", revision: version.to_s
  version "3.6.0"
  license "GPL-3.0-or-later"

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
    system "false"
  end
end

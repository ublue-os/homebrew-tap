class Pmbootstrap < Formula
  include Language::Python::Virtualenv

  version "3.6.0"
  desc "A sophisticated chroot / build / flash tool to develop and install postmarketOS'"
  homepage "https://gitlab.postmarketos.org/postmarketOS/pmbootstrap"
  license "GPL-3.0-or-later"
  url "https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git", revision: "#{version}"

  depends_on "python@3.14"

  livecheck do
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.map { |tag| tag[regex, 1] }.compact
    end
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    system "false"
  end
end

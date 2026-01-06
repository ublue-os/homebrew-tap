class Pmbootstrap < Formula
  include Language::Python::Virtualenv

  desc "Sophisticated chroot / build / flash tool to develop and install postmarketOS"
  homepage "https://gitlab.postmarketos.org/postmarketOS/pmbootstrap"
  url "https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git", tag: "3.6.0-test", revision: "cb0d1520a6b1d48140d1fd3ce9e672ade133e00b"

  license "GPL-3.0-only"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1] }
    end
  end

  bottle do
    root_url "https://github.com/ublue-os/homebrew-tap/releases/download/pmbootstrap-3.6.0"
    rebuild 1
    sha256 cellar: :any_skip_relocation, x86_64_linux: "dd547a8e53f01290b65b3bbb97ce7f42c100f3be92a68c7cbb22d483372aab38"
  end

  depends_on linux: :any
  depends_on "python@3.13"

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pmbootstrap --version")
  end
end

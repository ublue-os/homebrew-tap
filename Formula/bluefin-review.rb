class BluefinReview < Formula
  desc "Distroless review appliance for Project Bluefin"
  homepage "https://github.com/projectbluefin/review"
  url "https://github.com/projectbluefin/review/archive/bd1513a76f74d464fefbf4c918113813891a54f4.tar.gz"
  version "26.08.05"
  sha256 "7c91bc593f57ead1ab79279fd4e20f0dc48ebe5ed6cf646c9aa4d016162b5b40"
  license "Apache-2.0"

  on_macos do
    depends_on "node"
  end

  on_linux do
    depends_on "apptainer"
  end

  def install
    prefix.install "image", "scripts"

    if OS.linux?
      bin.install "bin/bluefin-review"
    elsif OS.mac?
      bin.install "bin/omp-review" => "bluefin-review"
    end
  end

  test do
    assert_path_exists bin/"bluefin-review"
    system "bash", "-n", bin/"bluefin-review"
  end
end

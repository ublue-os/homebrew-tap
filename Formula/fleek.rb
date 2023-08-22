# typed: false
# frozen_string_literal: true

# This file was generated by GoReleaser. DO NOT EDIT.
class Fleek < Formula
  desc "Own your $HOME"
  homepage "https://getfleek.dev"
  version "0.9.19"
  license "Apache-2.0"

  depends_on "git"
  depends_on "go" => :optional

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/ublue-os/fleek/releases/download/0.9.19/fleek_0.9.19_darwin_amd64.tar.gz"
      sha256 "af8aeabd38cd8abb62cc30f4f3a457631ec72cd8b2a4c9923ade9e060839c135"

      def install
        bin.install "fleek"
      end
    end
    if Hardware::CPU.arm?
      url "https://github.com/ublue-os/fleek/releases/download/0.9.19/fleek_0.9.19_darwin_arm64.tar.gz"
      sha256 "e9b5e8dae3701681cdfda3e9d2f20e889b7bc41d127c0a488406dcfb7c95e9f7"

      def install
        bin.install "fleek"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/ublue-os/fleek/releases/download/0.9.19/fleek_0.9.19_linux_arm64.tar.gz"
      sha256 "0ae7f8d2b113234b5b7a886190165457cbab563c44028d588b5c5739f84b8df4"

      def install
        bin.install "fleek"
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/ublue-os/fleek/releases/download/0.9.19/fleek_0.9.19_linux_amd64.tar.gz"
      sha256 "d8263c9d3f90c6185c67a2576090f3cc6c31ffb0864b337244e714c1ea825f5b"

      def install
        bin.install "fleek"
      end
    end
  end

  test do
    system "#{bin}/fleek -v"
  end
end

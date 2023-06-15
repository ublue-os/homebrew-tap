# typed: false
# frozen_string_literal: true

# This file was generated by GoReleaser. DO NOT EDIT.
class Fleek < Formula
  desc "Own your $HOME"
  homepage "https://getfleek.dev"
  version "0.9.6"
  license "Apache-2.0"

  depends_on "go" => :optional
  depends_on "git"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/ublue-os/fleek/releases/download/v0.9.6/fleek_Darwin_arm64.tar.gz"
      sha256 "7c6a952d393247bb84c7b4a27b0f65790a56f6cd000f3848fd13f7b355ca6263"

      def install
        bin.install "fleek"
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/ublue-os/fleek/releases/download/v0.9.6/fleek_Darwin_x86_64.tar.gz"
      sha256 "3a17afecf12814e91abb6e9ae4df060c997549dbf0728790c0d294ddb6d1f3ea"

      def install
        bin.install "fleek"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/ublue-os/fleek/releases/download/v0.9.6/fleek_Linux_arm64.tar.gz"
      sha256 "97dd6d74de3e51d1990c8bb6e15b6b5bb389d5835d37f057daeb46d9b82755ae"

      def install
        bin.install "fleek"
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/ublue-os/fleek/releases/download/v0.9.6/fleek_Linux_x86_64.tar.gz"
      sha256 "60f8801ff1cc1ea4130a6e1089043f524be7dafe985e5ad42fc7a1b40fe52862"

      def install
        bin.install "fleek"
      end
    end
  end

  test do
    system "#{bin}/fleek -v"
  end
end

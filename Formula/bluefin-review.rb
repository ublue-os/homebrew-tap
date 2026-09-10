class BluefinReview < Formula
  desc "Distroless review appliance for Project Bluefin"
  homepage "https://github.com/projectbluefin/review"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/projectbluefin/review/releases/download/v26.08.3/bluefin-review-darwin-arm64.tar.gz"
      sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    end
    on_intel do
      url "https://github.com/projectbluefin/review/releases/download/v26.08.3/bluefin-review-darwin-x64.tar.gz"
      sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/projectbluefin/review/releases/download/v26.08.3/bluefin-review-aarch64.sif"
      sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    end
    on_intel do
      url "https://github.com/projectbluefin/review/releases/download/v26.08.3/bluefin-review-x86_64.sif"
      sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    end

    depends_on "apptainer"
  end

  def install
    if OS.linux?
      arch_sif = Hardware::CPU.intel? ? "bluefin-review-x86_64.sif" : "bluefin-review-aarch64.sif"
      libexec.install arch_sif => "bluefin-review.sif"

      (bin/"bluefin-review").write <<~SHELL
        #!/usr/bin/env bash
        set -euo pipefail

        SIF="#{libexec}/bluefin-review.sif"
        if [[ ! -f "$SIF" ]]; then
          echo "Error: Bluefin review appliance image not found at $SIF" >&2
          exit 1
        fi

        STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/bluefin-review"
        mkdir -p "$STATE_DIR"

        APPTAINER_ARGS=(
          run
          --containall
          --pwd /workspace
          --bind "${PWD}:/workspace"
          --bind "${STATE_DIR}:/home/bluefin/.local/state/bluefin-review"
        )

        # Terminal passthrough environment
        [[ -n "${TERM:-}" ]] && APPTAINER_ARGS+=(--env "TERM=${TERM}")
        [[ -n "${COLORTERM:-}" ]] && APPTAINER_ARGS+=(--env "COLORTERM=${COLORTERM}")

        # GitHub token credentials
        [[ -n "${GH_TOKEN:-}" ]] && APPTAINER_ARGS+=(--env "GH_TOKEN=${GH_TOKEN}")
        [[ -n "${GITHUB_TOKEN:-}" ]] && APPTAINER_ARGS+=(--env "GITHUB_TOKEN=${GITHUB_TOKEN}")

        # Hardware virtualization support
        if [[ -e /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
          APPTAINER_ARGS+=(--bind /dev/kvm)
        fi

        # Tiered gVisor (runsc) sandbox support
        if command -v runsc >/dev/null 2>&1 || [[ -x /usr/bin/runsc ]]; then
          APPTAINER_ARGS+=(--env "BLUEFIN_SANDBOX=gvisor")
        fi

        exec apptainer "${APPTAINER_ARGS[@]}" "$SIF" "$@"
      SHELL
    else
      # macOS native binary + extension payload
      libexec.install Dir["*"]
      (bin/"bluefin-review").write <<~SHELL
        #!/usr/bin/env bash
        set -euo pipefail
        exec "#{libexec}/bin/omp" --profile review --extension "#{libexec}/extension" "$@"
      SHELL
    end

    chmod 0755, bin/"bluefin-review"
  end

  test do
    assert_path_exists bin/"bluefin-review"
  end
end

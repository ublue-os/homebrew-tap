class BluefinReview < Formula
  desc "Distroless review appliance for Project Bluefin"
  homepage "https://github.com/projectbluefin/review"
  version "26.08.3"
  license "Apache-2.0"

  depends_on "apptainer"
  depends_on :linux

  on_linux do
    on_intel do
      url "https://github.com/projectbluefin/review/releases/download/v#{version}/bluefin-review-x86_64.sif"
      sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" # placeholder sha256 until release asset is published
    end
    on_arm do
      url "https://github.com/projectbluefin/review/releases/download/v#{version}/bluefin-review-aarch64.sif"
      sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" # placeholder sha256 until release asset is published
    end
  end

  def install
    libexec.install "bluefin-review-#{Hardware::CPU.arch}.sif" => "bluefin-review.sif"

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

      # Pass terminal passthrough environment
      [[ -n "${TERM:-}" ]] && APPTAINER_ARGS+=(--env "TERM=${TERM}")
      [[ -n "${COLORTERM:-}" ]] && APPTAINER_ARGS+=(--env "COLORTERM=${COLORTERM}")

      # Pass GitHub tokens if present
      [[ -n "${GH_TOKEN:-}" ]] && APPTAINER_ARGS+=(--env "GH_TOKEN=${GH_TOKEN}")
      [[ -n "${GITHUB_TOKEN:-}" ]] && APPTAINER_ARGS+=(--env "GITHUB_TOKEN=${GITHUB_TOKEN}")

      # KVM hardware virtualization support
      if [[ -e /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
        APPTAINER_ARGS+=(--bind /dev/kvm)
      fi

      # Tiered gVisor (runsc) sandbox support
      RUNSC_BIN=""
      if command -v runsc >/dev/null 2>&1; then
        RUNSC_BIN="$(command -v runsc)"
      elif [[ -x /usr/bin/runsc ]]; then
        RUNSC_BIN="/usr/bin/runsc"
      fi

      if [[ -n "$RUNSC_BIN" ]]; then
        # gVisor runtime detected
        # Pass host-uds=open if apptainer/runsc flags are applicable or signal gVisor mode
        APPTAINER_ARGS+=(--env "BLUEFIN_SANDBOX=gvisor")
      fi

      exec apptainer "${APPTAINER_ARGS[@]}" "$SIF" "$@"
    SHELL

    chmod 0755, bin/"bluefin-review"
  end

  test do
    assert_predicate bin/"bluefin-review", :exist?
    assert_predicate bin/"bluefin-review", :executable?
  end
end

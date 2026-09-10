class BluefinReview < Formula
  desc "Distroless review appliance for Project Bluefin"
  homepage "https://github.com/projectbluefin/review"
  url "https://github.com/projectbluefin/review/archive/315bc5364633d4482b493aefb9d24f177a29d6ff.tar.gz"
  version "26.08.3"
  sha256 "b071afdf7f00a32a2e313ffd40ad1e1aa349d219aeefee5e4644f461077f1ee3"
  license "Apache-2.0"

  on_linux do
    depends_on "apptainer"
  end

  def install
    if OS.linux?
      (bin/"bluefin-review").write <<~SHELL
        #!/usr/bin/env bash
        set -euo pipefail

        STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/bluefin-review"
        mkdir -p "$STATE_DIR"

        IMAGE="${BLUEFIN_REVIEW_IMAGE:-ghcr.io/projectbluefin/review:stable}"

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

        exec apptainer "${APPTAINER_ARGS[@]}" "docker://${IMAGE}" "$@"
      SHELL
    else
      # macOS native wrapper
      (bin/"bluefin-review").write <<~SHELL
        #!/usr/bin/env bash
        set -euo pipefail
        exec omp --profile review --extension "#{opt_prefix}/image/extension/bluefin-review" "$@"
      SHELL
    end

    prefix.install "image"
    chmod 0755, bin/"bluefin-review"
  end

  test do
    assert_path_exists bin/"bluefin-review"
  end
end

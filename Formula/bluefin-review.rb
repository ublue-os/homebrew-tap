class BluefinReview < Formula
  desc "Distroless review appliance for Project Bluefin"
  homepage "https://github.com/projectbluefin/review"
  url "https://github.com/projectbluefin/review/archive/refs/tags/v26.08.05.tar.gz"
  version "26.08.05"
  sha256 "3e7f5f4c10a116497011c49536b356c7ff1a51e84d234e2a7551b6fb41ab2f4d"
  license "Apache-2.0"

  on_linux do
    depends_on "apptainer"
  end

  def install
    if OS.linux?
      (bin/"bluefin-review").write <<~'SHELL'
        #!/usr/bin/env bash
        set -euo pipefail

        STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/bluefin-review"
        mkdir -p "$STATE_DIR"
        sif="${BLUEFIN_REVIEW_SIF:-$STATE_DIR/bluefin-review.sif}"

        if [[ ! -x "$sif" ]]; then
          IMAGE="${BLUEFIN_REVIEW_IMAGE:-docker://ghcr.io/projectbluefin/review:stable}"
          echo "bluefin-review: pulling review image (${IMAGE}) to ${sif} ..." >&2
          apptainer pull --force "$sif" "$IMAGE"
          chmod 0755 "$sif"
        fi

        APPTAINER_ARGS=(
          run
          --containall
          --home "${STATE_DIR}:/home/bluefin"
          --pwd /workspace
          --bind "${PWD}:/workspace"
        )

        # Forward host configs into container automatically
        for cfg in "${HOME}/.gitconfig:/home/bluefin/.gitconfig:ro" \
                   "${HOME}/.config/hive:/home/bluefin/.config/hive:ro" \
                   "${HOME}/.config/gh:/home/bluefin/.config/gh:ro" \
                   "${HOME}/.omp:/home/bluefin/.omp:rw"; do
          src="${cfg%%:*}"
          if [[ -e "$src" ]]; then
            APPTAINER_ARGS+=(--bind "$cfg")
          fi
        done

        # Resolve HIVE_HUB from contributor.env if unset
        if [[ -z "${HIVE_HUB:-}" && -f "${HOME}/.config/hive/contributor.env" ]]; then
          resolved_hub="$(sed -nE 's/^[[:space:]]*(export[[:space:]]+)?HIVE_HUB=[[:space:]]*["'\'']?([^"'\'']+)["'\'']?/\2/p' "${HOME}/.config/hive/contributor.env" | head -1 || true)"
          [[ -n "$resolved_hub" ]] && export HIVE_HUB="$resolved_hub"
        fi

        # Resolve GitHub tokens if not explicitly set
        if [[ -z "${GH_TOKEN:-}" && -z "${GITHUB_TOKEN:-}" ]] && command -v gh >/dev/null 2>&1; then
          resolved_gh="$(gh auth token 2>/dev/null || true)"
          if [[ -n "$resolved_gh" ]]; then
            export GH_TOKEN="$resolved_gh"
            export GITHUB_TOKEN="$resolved_gh"
          fi
        fi

        # Fallback to host omp auth credentials
        if [[ -z "${GH_TOKEN:-}" && -z "${GITHUB_TOKEN:-}" ]] && command -v python3 >/dev/null 2>&1; then
          resolved_omp="$(python3 -c '
import sqlite3, os, json
db_path = os.path.expanduser("~/.omp/agent/agent.db")
if os.path.exists(db_path):
    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        for prov in ("github-copilot", "github"):
            row = cur.execute("SELECT data FROM auth_credentials WHERE provider = ?", (prov,)).fetchone()
            if row:
                d = json.loads(row[0])
                tok = d.get("access") or d.get("token") or d.get("access_token")
                if tok:
                    print(tok)
                    break
    except Exception:
        pass
' 2>/dev/null || true)"
          if [[ -n "$resolved_omp" ]]; then
            export GH_TOKEN="$resolved_omp"
            export GITHUB_TOKEN="$resolved_omp"
            export COPILOT_GITHUB_TOKEN="$resolved_omp"
            export GITHUB_COPILOT_TOKEN="$resolved_omp"
          fi
        fi

        export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
        export GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
        export COPILOT_GITHUB_TOKEN="${COPILOT_GITHUB_TOKEN:-${GH_TOKEN:-}}"
        export GITHUB_COPILOT_TOKEN="${GITHUB_COPILOT_TOKEN:-${COPILOT_GITHUB_TOKEN}}"
        export COPILOT_INTEGRATION_ID="${COPILOT_INTEGRATION_ID:-copilot-developer-cli}"

        # Terminal passthrough environment
        [[ -n "${TERM:-}" ]] && APPTAINER_ARGS+=(--env "TERM=${TERM}")
        [[ -n "${COLORTERM:-}" ]] && APPTAINER_ARGS+=(--env "COLORTERM=${COLORTERM}")

        # Hive hub endpoint
        [[ -n "${HIVE_HUB:-}" ]] && APPTAINER_ARGS+=(--env "HIVE_HUB=${HIVE_HUB}")

        # GitHub token credentials
        [[ -n "${GH_TOKEN:-}" ]] && APPTAINER_ARGS+=(--env "GH_TOKEN=${GH_TOKEN}")
        [[ -n "${GITHUB_TOKEN:-}" ]] && APPTAINER_ARGS+=(--env "GITHUB_TOKEN=${GITHUB_TOKEN}")
        [[ -n "${COPILOT_GITHUB_TOKEN:-}" ]] && APPTAINER_ARGS+=(--env "COPILOT_GITHUB_TOKEN=${COPILOT_GITHUB_TOKEN}")
        [[ -n "${GITHUB_COPILOT_TOKEN:-}" ]] && APPTAINER_ARGS+=(--env "GITHUB_COPILOT_TOKEN=${GITHUB_COPILOT_TOKEN}")
        [[ -n "${COPILOT_INTEGRATION_ID:-}" ]] && APPTAINER_ARGS+=(--env "COPILOT_INTEGRATION_ID=${COPILOT_INTEGRATION_ID}")

        # Hardware virtualization support
        if [[ -e /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
          APPTAINER_ARGS+=(--bind /dev/kvm)
        fi

        # Tiered gVisor (runsc) sandbox support
        if command -v runsc >/dev/null 2>&1 || [[ -x /usr/bin/runsc ]]; then
          APPTAINER_ARGS+=(--env "BLUEFIN_SANDBOX=gvisor")
        fi

        # Parse review arguments using the canonical helper
        opt_prefix="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
        if [[ -f "${opt_prefix}/scripts/parse-review-args.sh" ]]; then
          source "${opt_prefix}/scripts/parse-review-args.sh"
          parse_review_args "$@"
          APPLIANCE_ARGS=("${PARSED_REVIEW_ARGS[@]}")
        else
          APPLIANCE_ARGS=("$@")
        fi

        exec apptainer "${APPTAINER_ARGS[@]}" "$sif" ${APPLIANCE_ARGS[@]+"${APPLIANCE_ARGS[@]}"}
      SHELL
      (bin/"bluefin-review").chmod 0755
    else
      # macOS native wrapper
      (bin/"bluefin-review").write <<~'SHELL'
        #!/usr/bin/env bash
        set -euo pipefail
        opt_prefix="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
        exec omp --profile review --extension "${opt_prefix}/image/extension/bluefin-review" "$@"
      SHELL
      (bin/"bluefin-review").chmod 0755
    end

    prefix.install "image", "scripts"
  end

  test do
    assert_path_exists bin/"bluefin-review"
  end
end

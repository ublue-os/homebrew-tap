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
      (bin/"bluefin-review").write <<~SHELL
        #!/usr/bin/env bash
        set -euo pipefail

        STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/bluefin-review"
        mkdir -p "$STATE_DIR"

        IMAGE="${BLUEFIN_REVIEW_IMAGE:-ghcr.io/projectbluefin/review:stable}"

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
        export GITHUB_COPILOT_TOKEN="${GITHUB_COPILOT_TOKEN:-${COPILOT_GITHUB_TOKEN}}"
        export COPILOT_INTEGRATION_ID="${COPILOT_INTEGRATION_ID:-copilot-developer-cli}"
            export GITHUB_COPILOT_TOKEN="$resolved_omp"
          fi
        fi

        export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
        export GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
        export COPILOT_GITHUB_TOKEN="${COPILOT_GITHUB_TOKEN:-${GH_TOKEN:-}}"
        export GITHUB_COPILOT_TOKEN="${GITHUB_COPILOT_TOKEN:-${COPILOT_GITHUB_TOKEN}}"
        export COPILOT_INTEGRATION_ID="${COPILOT_INTEGRATION_ID:-copilot-developer-cli}"

        APPTAINER_ARGS=(
          run
          --containall
          --home "${STATE_DIR}:/home/bluefin"
          --pwd /workspace
          --bind "${PWD}:/workspace"
        )

        # Terminal passthrough environment
        [[ -n "${TERM:-}" ]] && APPTAINER_ARGS+=(--env "TERM=${TERM}")
        [[ -n "${COLORTERM:-}" ]] && APPTAINER_ARGS+=(--env "COLORTERM=${COLORTERM}")

        # GitHub token credentials
        [[ -n "${GH_TOKEN:-}" ]] && APPTAINER_ARGS+=(--env "GH_TOKEN=${GH_TOKEN}")
        [[ -n "${GITHUB_TOKEN:-}" ]] && APPTAINER_ARGS+=(--env "GITHUB_TOKEN=${GITHUB_TOKEN}")
        [[ -n "${COPILOT_GITHUB_TOKEN:-}" ]] && APPTAINER_ARGS+=(--env "COPILOT_GITHUB_TOKEN=${COPILOT_GITHUB_TOKEN}")
        [[ -n "${GITHUB_COPILOT_TOKEN:-}" ]] && APPTAINER_ARGS+=(--env "GITHUB_COPILOT_TOKEN=${GITHUB_COPILOT_TOKEN}")
        [[ -n "${COPILOT_INTEGRATION_ID:-}" ]] && APPTAINER_ARGS+=(--env "COPILOT_INTEGRATION_ID=${COPILOT_INTEGRATION_ID}")

        # Bind host configs into container
        for cfg in "${HOME}/.gitconfig:/home/bluefin/.gitconfig:ro" \
                   "${HOME}/.config/hive:/home/bluefin/.config/hive:ro" \
                   "${HOME}/.config/gh:/home/bluefin/.config/gh:ro" \
                   "${HOME}/.omp:/home/bluefin/.omp:rw"; do
          src="${cfg%%:*}"
          if [[ -e "$src" ]]; then
            APPTAINER_ARGS+=(--bind "$cfg")
          fi
        done

        # Hardware virtualization support
        if [[ -e /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
          APPTAINER_ARGS+=(--bind /dev/kvm)
        fi

        # Tiered gVisor (runsc) sandbox support
        if command -v runsc >/dev/null 2>&1 || [[ -x /usr/bin/runsc ]]; then
          APPTAINER_ARGS+=(--env "BLUEFIN_SANDBOX=gvisor")
        fi

        # Positional arguments mapping
        app_args=()
        if [[ "${1:-}" =~ ^#?[0-9]+$ ]]; then
          app_args+=(--pr "${1#\\#}")
          shift
        elif [[ "${1:-}" =~ ^(https://github\\.com/)?[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ || "${1:-}" =~ ^org:[A-Za-z0-9._-]+$ ]]; then
          app_args+=(--repo "$1")
          shift
          if [[ "${1:-}" =~ ^#?[0-9]+$ ]]; then
            app_args+=(--pr "${1#\\#}")
            shift
          fi
        fi
        if [[ "${1:-}" == "issues" || "${1:-}" == "--issues" ]]; then
          app_args+=(--issues)
          shift
        elif [[ "${1:-}" == "all" || "${1:-}" == "--all" ]]; then
          app_args+=(--all)
          shift
        elif [[ "${1:-}" == "autoslay" || "${1:-}" == "--autoslay" || "${1:-}" == "slay" ]]; then
          app_args+=(--autoslay)
          shift
        fi

        exec apptainer "${APPTAINER_ARGS[@]}" "docker://${IMAGE}" ${app_args[@]+"${app_args[@]}"} "$@"
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

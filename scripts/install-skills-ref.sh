#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${SKILLS_REF_VENV_DIR:-$ROOT_DIR/.tools/skills-ref}"
SKILLS_REF_REF="${SKILLS_REF_GIT_REF:-2e8b3265237b2e5f255d6e675f89ae83be572329}"
SKILLS_REF_PACKAGE="git+https://github.com/agentskills/agentskills.git@${SKILLS_REF_REF}#subdirectory=skills-ref"
INSTALLED_REF_FILE="$VENV_DIR/.skills_ref_installed_ref"

if [ "${SKILLS_REF_ALLOW_PATH:-0}" = "1" ] && [ "${SKILLS_REF_FORCE_LOCAL:-0}" != "1" ]; then
  PATH_SKILLS_REF="$(command -v skills-ref || true)"
  if [ -n "$PATH_SKILLS_REF" ]; then
    if [ -z "${SKILLS_REF_PINNED_VERSION:-}" ]; then
      echo "SKILLS_REF_ALLOW_PATH=1 requires SKILLS_REF_PINNED_VERSION to verify the PATH-installed skills-ref." >&2
      exit 1
    fi

    PATH_VERSION="$($PATH_SKILLS_REF --version 2>/dev/null || true)"
    if printf '%s' "$PATH_VERSION" | grep -Fq "$SKILLS_REF_PINNED_VERSION"; then
      printf '%s\n' "$PATH_SKILLS_REF"
      exit 0
    fi

    echo "PATH-installed skills-ref does not match SKILLS_REF_PINNED_VERSION=$SKILLS_REF_PINNED_VERSION; using the repo-pinned validator instead." >&2
  fi
fi

if [ ! -x "$VENV_DIR/bin/skills-ref" ] || [ ! -f "$INSTALLED_REF_FILE" ] || [ "$(cat "$INSTALLED_REF_FILE" 2>/dev/null || true)" != "$SKILLS_REF_REF" ] || [ "${SKILLS_REF_FORCE_LOCAL:-0}" = "1" ]; then
  rm -rf "$VENV_DIR"
  mkdir -p "$VENV_DIR"
  python3 -m venv "$VENV_DIR"
  "$VENV_DIR/bin/pip" install --upgrade pip >/dev/null
  "$VENV_DIR/bin/pip" install --upgrade --force-reinstall "$SKILLS_REF_PACKAGE" >/dev/null
  printf '%s\n' "$SKILLS_REF_REF" > "$INSTALLED_REF_FILE"
fi

printf '%s\n' "$VENV_DIR/bin/skills-ref"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${SKILLS_REF_VENV_DIR:-$ROOT_DIR/.tools/skills-ref}"
SKILLS_REF_REF="${SKILLS_REF_GIT_REF:-2e8b3265237b2e5f255d6e675f89ae83be572329}"
SKILLS_REF_PACKAGE="git+https://github.com/agentskills/agentskills.git@${SKILLS_REF_REF}#subdirectory=skills-ref"

if command -v skills-ref >/dev/null 2>&1 && [ "${SKILLS_REF_FORCE_LOCAL:-0}" != "1" ]; then
  command -v skills-ref
  exit 0
fi

if [ ! -x "$VENV_DIR/bin/skills-ref" ]; then
  mkdir -p "$VENV_DIR"
  python3 -m venv "$VENV_DIR"
  "$VENV_DIR/bin/pip" install --upgrade pip >/dev/null
  "$VENV_DIR/bin/pip" install "$SKILLS_REF_PACKAGE" >/dev/null
fi

printf '%s\n' "$VENV_DIR/bin/skills-ref"

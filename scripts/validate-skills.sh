#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT_DIR/skills"

if [ ! -d "$SKILLS_DIR" ]; then
  echo "skills directory not found: $SKILLS_DIR" >&2
  exit 1
fi

SKILLS_REF_BIN="$("$ROOT_DIR/scripts/install-skills-ref.sh")"

validated=0
for skill_dir in "$SKILLS_DIR"/*; do
  [ -d "$skill_dir" ] || continue

  if [ ! -f "$skill_dir/SKILL.md" ]; then
    echo "[FAIL] $(basename "$skill_dir"): missing SKILL.md" >&2
    exit 1
  fi

  echo "[INFO] skills-ref validate $(basename "$skill_dir")"
  "$SKILLS_REF_BIN" validate "$skill_dir"
  validated=$((validated + 1))
done

echo "[INFO] validated $validated skill(s) with skills-ref"
python3 "$ROOT_DIR/scripts/validate_skills.py"

#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path


ALLOWED_TOP_LEVEL = {
    "name",
    "description",
    "license",
    "compatibility",
    "metadata",
    "allowed-tools",
}


def extract_frontmatter(text: str) -> tuple[list[str], str]:
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        raise ValueError("missing frontmatter start")

    end_index = None
    for idx in range(1, len(lines)):
        if lines[idx] == "---":
            end_index = idx
            break

    if end_index is None:
        raise ValueError("unterminated frontmatter")

    return lines[1:end_index], "\n".join(lines[end_index + 1 :])


def top_level_keys(frontmatter_lines: list[str]) -> list[str]:
    keys: list[str] = []
    for line in frontmatter_lines:
        if not line or line.startswith(" ") or line.startswith("\t"):
            continue
        if ":" not in line:
            continue
        keys.append(line.split(":", 1)[0].strip())
    return keys


def extract_description(frontmatter_lines: list[str]) -> str:
    for index, line in enumerate(frontmatter_lines):
        if not line.startswith("description:"):
            continue

        value = line.split(":", 1)[1].strip()
        if value and value not in {">", ">-", "|", "|-"}:
            return value

        collected: list[str] = []
        for next_line in frontmatter_lines[index + 1 :]:
            if next_line.startswith((" ", "\t")):
                collected.append(next_line.strip())
                continue
            if next_line and not next_line.startswith((" ", "\t")):
                break

        return " ".join(part for part in collected if part)

    return ""


def validate_skill(skill_dir: Path) -> list[str]:
    problems: list[str] = []
    skill_file = skill_dir / "SKILL.md"
    text = skill_file.read_text()

    try:
        frontmatter_lines, body = extract_frontmatter(text)
    except ValueError as exc:
        return [str(exc)]

    keys = top_level_keys(frontmatter_lines)
    description = extract_description(frontmatter_lines)
    extras = sorted(set(keys) - ALLOWED_TOP_LEVEL)
    if extras:
        problems.append(f"non-standard top-level fields: {', '.join(extras)}")

    if len(text.splitlines()) > 500:
        problems.append("SKILL.md exceeds 500 lines")

    if not body.strip():
        problems.append("SKILL.md body is empty")

    if "Use when" not in description:
        problems.append(
            "description should include an explicit 'Use when' activation cue"
        )

    references_dir = skill_dir / "references"
    if references_dir.exists():
        nested = [
            path.relative_to(skill_dir)
            for path in references_dir.glob("**/*")
            if path.is_file() and len(path.relative_to(skill_dir).parts) > 2
        ]
        if nested:
            preview = ", ".join(str(path) for path in nested[:3])
            problems.append(
                f"references should stay shallow; found nested files: {preview}"
            )

    return problems


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    skills_root = root / "skills"
    failures: list[tuple[str, str]] = []

    for skill_dir in sorted(path for path in skills_root.iterdir() if path.is_dir()):
        skill_file = skill_dir / "SKILL.md"
        if not skill_file.exists():
            failures.append((skill_dir.name, "missing SKILL.md"))
            continue

        for problem in validate_skill(skill_dir):
            failures.append((skill_dir.name, problem))

    if failures:
        for skill_name, problem in failures:
            print(f"[FAIL] {skill_name}: {problem}")
        return 1

    print("[OK] repository-specific skill checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())

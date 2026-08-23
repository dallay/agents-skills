# Curated Skill Provenance

This record covers the Phase 1 Bobmatnyc migration. The copied content is preserved under the
canonical `skills/<local-id>/` directories; no Clerk, Angular, or TypeScript candidate is included
in this provenance record or migration scope. Those pre-existing untracked candidate files remain in
the worktree but are intentionally not part of this unit.

## Source and license evidence

- Repository: `https://github.com/bobmatnyc/claude-mpm-skills`
- Immutable source commit: `718070a7d622921b01687799a1f9613f36c6f615`
- Repository license evidence: root `LICENSE`, Git blob
  `0681078518541912c82325184af5edaab8ed5b2c`, MIT License, copyright 2025 Claude MPM Contributors.
- Commit evidence: GitHub commit API reports the immutable commit above and verified signature.
- Attribution: `bobmatnyc/claude-mpm-skills` / Claude MPM Contributors; source metadata is retained in
  each entrypoint's `metadata.source` and `metadata.source_commit` fields.

## Materialized entries

| Local ID | Source path | Source blob/path identity | Materialized files | Companion status |
|---|---|---|---|---|
| `drizzle-orm` | `toolchains/typescript/data/drizzle/` | `SKILL.md` blob `236ae67fa9b66c3d7200c961fc92d6b0c0baab5d`; metadata blob `e23493b8d5f12a3a77a9032194d9bac05d167bac`; references tree `043607220be54467a264ef3fef89c6b17ebe9013` | `SKILL.md`, `references/advanced-schemas.md`, `references/performance.md`, `references/query-patterns.md`, `references/vs-prisma.md` | All four links declared by the source entrypoint are present. |
| `pydantic` | `toolchains/python/validation/pydantic/` | `SKILL.md` blob `7d8c7eaccdb3bfdc8853c03af0fd8ce55281f53f`; metadata blob `a6d2520f96566cdd197f3a22ea7d85cd676d66f6` | Curated `SKILL.md` entrypoint plus `references/full-source.md` containing the complete source body | No body-linked companion directory was declared by the source. Full source retained as an explicit companion. |
| `sqlalchemy` | `toolchains/python/data/sqlalchemy/` | `SKILL.md` blob `a8899fe4232fbf80b3bb500940b88aef3065ffef`; metadata blob `2bbcfdcd2ee0c394ca3a7747ffa7443b00068f7e`; references tree `46e9f4899640a3d8f20a8a5bf25732a14f8b37ee` | Curated `SKILL.md` entrypoint, `references/full-source.md`, `references/sql-quality-antipatterns.md` | The declared `sql-quality-antipatterns.md` link is present; full source retained as an explicit companion. |

## Deferred candidates pending upstream SPDX or authorship confirmation

The following ten Phase 1 candidates remain **untracked** in this repository. None has been
materialized into a `skills/<local-id>/` directory and none has a `Materialized entries` row in
this file. Each entry below records the audit decision and the audit record that backs it.
Per-skill evidence lives under
`openspec/changes/phase1-e2e-mirror-catalog/evidence/<local-id>.md` (PR1a's change folder);
the summary audit is `openspec/changes/phase1-e2e-mirror-catalog/evidence/summary.md`.

### Clerk family — blocked by missing top-level SPDX at `clerk/skills`

| Local ID | Blocker |
|---|---|
| `clerk-setup` | Local bytes are `v2.3.0`; upstream `clerk/skills@main` is `v2.5.0`. Needs an older pinned commit to byte-match. `clerk/skills` repo has no top-level `LICENSE` file — `gh api repos/clerk/skills/license` returns 404. See `evidence/clerk-setup.md`. |
| `clerk-nextjs-patterns` | Byte-identical to upstream at `aac39ed99f18...` (blob `7a2c0d7c...`). Repo-level SPDX absent; per-file `license: MIT` is not authoritative. Also needs 5 companion `references/*.md` vendored. See `evidence/clerk-nextjs-patterns.md`. |
| `clerk-react-patterns` | Byte-identical to upstream at `aac39ed99f18...` (blob `84496131...`). Same SPDX gap; 4 companion refs vendoring still required. See `evidence/clerk-react-patterns.md`. |
| `clerk-vue-patterns` | Byte-identical to upstream at `aac39ed99f18...` (blob `0109b3d7...`). Same SPDX gap; 3 companion refs vendoring still required. See `evidence/clerk-vue-patterns.md`. |
| `clerk-astro-patterns` | Byte-identical to upstream at `aac39ed99f18...` (blob `0e5f731e...`). Same SPDX gap; 5 companion refs vendoring still required. See `evidence/clerk-astro-patterns.md`. |
| `clerk-webhooks` | Byte-identical to upstream at `aac39ed99f18...` (blob `259f099f...`). Same SPDX gap; 1 companion `references/frameworks.md` vendoring required. See `evidence/clerk-webhooks.md`. |
| `clerk-testing` | Byte-identical to upstream at `aac39ed99f18...` (blob `46b394e0...`). Same SPDX gap; no companion refs. See `evidence/clerk-testing.md`. |
| `clerk-custom-ui` | Byte-identical to upstream at `aac39ed99f18...` (blob `e6e05dc9...`). Same SPDX gap; 5 `core-2/` + `core-3/` companion refs vendoring required. See `evidence/clerk-custom-ui.md`. |

### dallay-original family — blocked by unconfirmed authorship

| Local ID | Blocker |
|---|---|
| `angular-architecture` | No upstream candidate; git history is empty for the untracked worktree entry. Frontmatter is missing `metadata.author` and `metadata.source`; prose reads as Yuniel-style but Yuniel has not confirmed authorship in writing. See `evidence/angular-architecture.md`. |
| `typescript-strict-patterns` | No upstream candidate; git history is empty for the untracked worktree entry. Frontmatter is missing `metadata.author` and `metadata.source`; prose reads as Yuniel-style but Yuniel has not confirmed authorship in writing. See `evidence/typescript-strict-patterns.md`. |

### Resolution

- Clerk candidates are gated on a top-level `LICENSE` file appearing at `clerk/skills` (or a
  written re-distribution grant from the Clerk org). A tracking issue in `dallay/agents-skills`
  records the SPDX / authorship gap for the family.
- The two `dallay-original` candidates are gated on Yuniel confirming authorship in writing so
  the frontmatter can be patched with `metadata.author: dallay-team` and
  `metadata.source: dallay-original` per REQ-SKILLREC-008 branch (a).

The `validate_provenance.py` script (unchanged for PR1b) does not inspect frontmatter and
therefore still exits 0 against this repository — this provenance note is a comment, not a hash
entry. The frontmatter precheck that would catch the missing `metadata.source` fields is
scoped to a future change after the upstream evidence resolves.

## Validation and transformation notes

The target repository's pinned `skills-ref` validator accepts the three materialized directories.
Run `python3 scripts/validate_provenance.py` from the repository root to verify every materialized
file hash below against the current bytes.
The upstream frontmatter used unsupported progressive-disclosure fields and, for Drizzle, the source
name `drizzle`; the curated entrypoints normalize only those repository packaging fields and retain
complete source guidance in the linked companion files. The catalog retains the existing local IDs,
titles, summaries, and installed-registry semantics.

Clerk candidates remain blocked and untouched because their license evidence/permission and companion
completeness were not verified. Existing unrelated untracked skills also remain untouched.

## Materialized file hashes

SHA-256 hashes of the final materialized files, refreshed during verification:

- `drizzle-orm/SKILL.md`: `d13bb172f93171606b04cb72b21d5b2ed39ddfccdd240ba6b42ebe88f04cad4a`
- `drizzle-orm/references/advanced-schemas.md`: `e71e8ec21a24b5e0d6e0759e3b4a7926767fbde1c47c69e9186bb6262ce15692`
- `drizzle-orm/references/performance.md`: `bc47e3926b70d961b45b3d748c63c3d15bd2fb4e29b4acb1e43190866732fbe8`
- `drizzle-orm/references/query-patterns.md`: `f291b839fde2008f3af5fec4b56c4af5dfdf437e33c28bdb79a369e13bdcde79`
- `drizzle-orm/references/vs-prisma.md`: `93a29571f1c02fd9c70b4a7a50491b311cdf820055395317dbec2468ec2d1ca4`
- `pydantic/SKILL.md`: `6769a7817671c8673e94221357d2e2058867594a006fdc05b3d551850cf4ff99`
- `pydantic/references/full-source.md`: `59ad03a0452eaf89b8c43ce3780fcc36443c710d45b53d9e373288ddc09d85b9`
- `sqlalchemy/SKILL.md`: `35e1956c80ec9b8644d6b67de13909696ee83191534a51bf0d7dbfdfca65df4b`
- `sqlalchemy/references/full-source.md`: `87059b5aaa81ab2e70977c327c50b26ebf7bd494a4f6badbe9a6a6c57db384df`
- `sqlalchemy/references/sql-quality-antipatterns.md`: `06d1875db687a9a6e25158cb2039e6382ebc7ca599dc94107fa0b332a306872a`

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

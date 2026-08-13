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
The upstream frontmatter used unsupported progressive-disclosure fields and, for Drizzle, the source
name `drizzle`; the curated entrypoints normalize only those repository packaging fields and retain
complete source guidance in the linked companion files. The catalog retains the existing local IDs,
titles, summaries, and installed-registry semantics.

Clerk candidates remain blocked and untouched because their license evidence/permission and companion
completeness were not verified. Existing unrelated untracked skills also remain untouched.

## Materialized file hashes

SHA-256 hashes of the final materialized files, refreshed during verification:

- `drizzle-orm/SKILL.md`: `31aab8f3fff9dc3b4dd0ac593f33d6b5e6583885db5a373dbcfd805b3732714f`
- `drizzle-orm/references/advanced-schemas.md`: `420e86801c18d535ab531e6621c8a9df5247c11158b9a9f30dc44f11ea35108d`
- `drizzle-orm/references/performance.md`: `7c7d88acf151be3cd992189999fce590599052979180fceac9fae9133d2bdf27`
- `drizzle-orm/references/query-patterns.md`: `2f6808e80fd63e7f07d47ade83bd2c89506c1fd4325b8e8b661257337c029778`
- `drizzle-orm/references/vs-prisma.md`: `a893597eede5b0a4a230fa34d321f97e25dc42529c6aaf760235d8ac05a9022e`
- `pydantic/SKILL.md`: `6769a7817671c8673e94221357d2e2058867594a006fdc05b3d551850cf4ff99`
- `pydantic/references/full-source.md`: `b370a330c9f2ca486b58e306853aae31edf5c70ca8fd24d3cfbb79127fe269a5`
- `sqlalchemy/SKILL.md`: `35e1956c80ec9b8644d6b67de13909696ee83191534a51bf0d7dbfdfca65df4b`
- `sqlalchemy/references/full-source.md`: `4ce69ba775e5c954a7201e1e4dc3863201ebd0887c64ea47efccbacc9b14631a`
- `sqlalchemy/references/sql-quality-antipatterns.md`: `564fb37be603f965d8f7678e5030cc5c9c4059d746bcb8f317ddd70a9d53fc11`

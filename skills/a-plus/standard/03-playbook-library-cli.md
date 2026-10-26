# Layer 3 — Library and CLI Playbook

**Status:** Reference v2.0. Applies when `roles` includes `library` (code other code imports:
SDKs, shared packages, internal libraries) or `cli` (programs people or scripts run from a
shell, including developer tools and automation scripts kept in the repository). Binds to
Layer 1 and 2 controls. Rows without an "Applies when" apply to both roles.

## 1. Structure

| Id | Applies when | Rule |
| --- | --- | --- |
| L-1 | | One public surface: the package exports only what callers need from one entry point (`__init__.py` with `__all__`, `index.ts` plus `exports` in `package.json`, an exported Go package, a crate's `lib.rs`); everything else is private by the language's convention. |
| L-2 | | The same inward layering as B-2: argument parsing or the public API is thin; logic lives in pure functions or classes testable without a shell, network or filesystem; I/O sits in adapters. |
| L-3 | | Importing a module has no side effects: no network, no file writes, no reading secrets, no global logging configuration, no process exit. Work starts from an explicit call or `main`. |
| L-4 | | Follow the ecosystem's packaging layout (`src/` layout with `pyproject.toml`, `package.json` with `exports` and types, Go modules, Cargo workspace). Scripts kept in the repository live in one declared folder and follow the same rules as product code. |

## 2. Contracts and compatibility

| Id | Applies when | Rule |
| --- | --- | --- |
| L-5 | `library` | Typed public API (type hints checked by a type checker, `.d.ts` emitted, exported Go types); errors are a documented, typed hierarchy, never bare strings. |
| L-6 | `library` with consumers outside the repository | Semantic versioning; a breaking change needs a major version, a migration note and a deprecation period; a public-API snapshot or API-extractor check fails on unintended change (P-C3). |
| L-7 | `cli` | The command surface is a contract: flags, subcommands, exit codes and machine-readable output (`--json` or equivalent) are documented and covered by tests; exit code `0` only on success, distinct non-zero codes per failure class. |
| L-8 | `cli` | stdout carries results; stderr carries logs, progress and errors. Output to a non-terminal has no colour or spinners. Prompts are skippable with flags for non-interactive use. |

## 3. Safety

| Id | Applies when | Rule |
| --- | --- | --- |
| L-9 | | Configuration precedence is explicit and documented (flags > environment > config file > defaults) and validated as one typed schema (C-06). |
| L-10 | | Subprocesses run with argument lists, never a shell string built from input; paths from input are resolved and confined (P-S13, P-S14). |
| L-11 | `cli` with destructive actions | Destructive actions need confirmation or `--yes`, offer `--dry-run`, and print what they will change before changing it. |
| L-12 | `cli` | Signals handled: interrupt stops cleanly, temporary files removed, partial output never left looking complete (write then rename). |
| L-13 | `delivery = package-registry` | Published artefacts built by CI from a tag, with provenance or signatures the registry supports, and no secrets or test data in the package (C-14, P-S22). |

## 4. Observability

| Id | Applies when | Rule |
| --- | --- | --- |
| L-14 | `library` | A library never configures global logging; it logs through a named logger or accepts one, and raises typed errors instead of printing. |
| L-15 | `cli` | `--verbose` and `--quiet` levels; structured logs available (`--log-format json`) for automation; a failure prints one actionable line plus the error code, with the trace only at verbose level (C-15). |

## 5. Tests the library or CLI owes

Unit tests for every public function and error path; for `cli`, tests that run the command
in-process or as a subprocess and assert exit code, stdout and stderr; golden-file tests for
machine-readable output; public-API snapshot when L-6 applies; tests on every supported
runtime version in the gate matrix.

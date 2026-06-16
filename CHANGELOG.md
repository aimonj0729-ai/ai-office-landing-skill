# Changelog

All notable changes to AI Office Landing Skill will be documented in this file.

## [Unreleased]

### Changed
- `install.sh` now accepts `--force` / `--yes` / `-y` for unattended reinstall flows, and it fails fast with guidance instead of waiting for interactive input when a previous install already exists
- `setup-github-repo.sh` now emits install examples that run `install.sh` from a temporary full repo checkout instead of a raw single-file script or the final install directory, and the README now documents the same constraint
- `SKILL.md` state-management examples now use the repository's helper functions (`ensure_state_initialized`, `mark_task_completed`, `add_pending_question`, `create_checkpoint`, etc.) instead of showing direct `jq` writes that no longer match the shipped scripts

### Fixed
- `cost-tracker.sh` now falls back to JSON string writes when `update_cost_db` receives plain text, while preserving existing numeric/object writes; this makes the helper safer for external automation that records notes or status fields.
- `orchestrator.sh` now renders the progress dashboard directly instead of overwriting the shared `/tmp/progress_table.md` path, preventing concurrent runs from corrupting each other's intermediate output or clobbering an existing file
- `install.sh reinstall` now moves the previous installation to a timestamped backup before installing the replacement, instead of deleting the working copy first
- `setup-github-repo.sh` now passes its own repository root to `gh repo create --source`, so invoking the publisher from another working directory cannot publish the wrong folder
- `examples/test.sh` now validates the actual installed skill, manifest version, critical files, and executable core scripts instead of always printing a successful installation result
- `setup-github-repo.sh` is now executable in fresh checkouts, so the documented `./setup-github-repo.sh` command no longer fails with `Permission denied`; a regression test now detects entrypoint mode regressions
- `install.sh install` and `reinstall` now reject execution when the source checkout is already the final `~/.claude/skills/ai-office-landing` directory, before moving or deleting anything, so an unsafe self-install cannot leave a partial installation
- `state-management.sh` now quotes and JSON-escapes the default project name during `init_state`, so direct initialization from checkout paths containing spaces or project names containing quotes no longer writes invalid `ai-office/state.json`
- `cost-tracker.sh` now validates `CLAUDE_PRO_LIMIT`, uses safe jq path updates for cost database keys, and avoids direct limit division so invalid limits or phase labels like `phase-3` no longer abort cost recording
- `orchestrator.sh` now degrades cleanly when one or more Phase 3 outputs are missing: it warns, keeps generating `orchestrator-summary.md`, and reports a partial status instead of aborting under `set -e` or tripping over a `0/4` completion-count arithmetic error
- `install.sh check` now works as a real unattended health check: it returns non-zero when the skill is missing, partially installed, or has a broken `.claude-plugin/manifest.json`, and it prints actionable `install` / `reinstall --force` guidance instead of raw `jq` errors
- `discover-skills.sh` no longer scans arbitrary sibling repositories when run from a source checkout; discovery now stays inside the current skill plus known Claude skill registries, and `info` / `load` prefer the current checkout over an older installed copy with the same name
- `setup-github-repo.sh` now tells the no-`gh` manual publish fallback to create an empty GitHub repository instead of pre-populating README / `.gitignore` / LICENSE, so the follow-up `git push -u origin main` no longer points users at a non-fast-forward first push
- `state-management.sh` now parses `read_state` / `write_state` / `append_to_state_array` keys into safe jq path arrays before calling `getpath` / `setpath`, so direct paths like `outputs_status.design-references` and bracket-quoted keys like `skills.loaded.designer["ai-office-landing"]` no longer abort unattended runs with jq compile errors
- `state-management.sh` now passes freeform pending-question text, source names, and checkpoint text into `jq` via `--arg` / `--argjson`, so quotes inside conversational prompts no longer trigger compile errors or break `ai-office/state.json`
- Removed stale `SKILL.md` snippets that still taught direct `jq ".$key = $value"` / `pending_questions[0]` / `outputs_status.$role` state writes, so the docs no longer point users back to patterns already fixed in `state-management.sh`
- `setup-github-repo.sh` now points the no-`gh` manual publish fallback at the current local checkout instead of a hardcoded `/tmp/ai-office-landing` path, and it can also substitute `GITHUB_OWNER` / `REPO_OWNER` into the suggested `git remote add origin` command
- `install.sh` now validates `~/.claude/settings.json` before copying files and fails fast when the file is invalid JSON or `.skills` is not an object, so unattended installs no longer print a misleading success message after a `jq` parse error
- `setup-github-repo.sh` now exits immediately when `gh auth status`, `gh repo create`, or GitHub user lookup fails, so a rejected publish attempt no longer falls through to a false "repository created successfully" message
- `setup-github-repo.sh` now substitutes the resolved GitHub owner into its post-publish tarball, `git clone`, and `curl` install examples, so release output no longer leaves users with `your-username` placeholder URLs that 404
- `install.sh uninstall` now removes the `ai-office-landing` entry from `~/.claude/settings.json`, so uninstalling the skill no longer leaves a stale `SKILL.md` path behind
- Reworked `state-management.sh` object field access to use literal jq keys, so output IDs like `design-references` and `brief.md` can be marked/read correctly instead of failing or creating nested `outputs_status.brief.md` entries
- Aligned `.claude-plugin/manifest.json` and `install.sh` with the current root-level `interview.md`, so fresh installs no longer fail on the stale `prompts/interviewer.md` path
- Replaced the `discover-skills.sh` `info` / `load` lookup with a path-safe `find -print0` helper and jq-safe state key writes, so skills still resolve and load correctly when directories contain spaces or the skill name contains hyphens like `ai-office-landing`
- Prevented `discover-skills.sh` and `orchestrator.sh` from resetting an existing `ai-office/state.json`; they now initialize workflow state only when the file is missing
- Synced the plugin manifest and user-facing shell script version output to `2.4.0`, so install/release/discovery helpers no longer report stale `v2.3` metadata
- Updated `discover-skills.sh info` to read description/version from `manifest.json` instead of stale hardcoded parsing
- Repaired `discover-skills.sh` so `auto-designer` and `suggest` run again after a broken shell fragment was introduced
- Skill discovery now deduplicates matches and skips the current `ai-office-landing` skill during Designer auto-discovery
- Fixed `cost-tracker.sh` initialization so it restores the current day's usage from `~/.claude/cost-history.json`
- Removed the Bash 4-only phase cost map from `cost-tracker.sh` and added a `numfmt` fallback for macOS environments without GNU coreutils
- Reworked `orchestrator.sh` to auto-detect `SKILL_ROOT` and avoid Bash 4 associative arrays, so the script can run under macOS's default Bash 3.2
- Lowered the documented installer/runtime Bash requirement from `4.0` to `3.2` in `install.sh` and `.claude-plugin/manifest.json`

## [2.4.0] - 2026-04-12

### Added
- **Kimi API adapter** (`adapters/kimi-api.sh`) — Moonshot API integration for cost-effective Executor fallback
- **DeepSeek API adapter** (`adapters/deepseek-api.sh`) — DeepSeek API integration, auto-selects `deepseek-coder` for Frontend role
- **Adapter router** (`adapters/route.sh`) — automatic adapter selection based on role quality tier and environment
- `--cost-saving` flag and `COST_SAVING_MODE` env var for automatic cheap-model routing
- `--adapter <name>` flag to force a specific adapter for all Executors
- HIGH-tier role protection: Critic, Interviewer, Integrator cannot be downgraded even when forced
- Token usage logging to `ai-office/cost/usage.jsonl` for API-based adapters

### Changed
- SKILL.md Phase 3 execution now routes through `adapters/route.sh` instead of direct `execute_task`
- README updated to v2.4.0 with adapter documentation

### Removed
- Cleaned up backup files (`*.backup`, `*.with-mapfile`, `fix-mapfile.sh`)

## [2.3.0] - 2026-04-11

### Added
- Phase 3.5 Orchestrator for automatic output summarization
- Dynamic Skill discovery (`discover-skills.sh`)
- Gap & Conflict reporting across Agent outputs
- Progress dashboard visualization
- Cost tracking with `cost-tracker.sh`
- Benchmark analysis for Critic enhancement

## [2.2.0] - 2026-04-11

### Added
- Real-time token consumption tracking
- Rate limit warning and auto-detection

## [2.0.0] - 2026-04-11

### Added
- Conversational interaction during execution
- Designer material search via web
- Incremental delivery with user confirmation

## [1.0.0] - 2026-04-11

### Added
- Initial release: 5-phase Agent collaboration workflow
- Living Brief as single source of truth
- Independent Critic review
- Style token auto-translation (hex/px)
- Checkpoint-based resume

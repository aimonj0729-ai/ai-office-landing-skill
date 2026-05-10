# Changelog

All notable changes to AI Office Landing Skill will be documented in this file.

## [Unreleased]

### Changed
- `install.sh` now accepts `--force` / `--yes` / `-y` for unattended reinstall flows, and it fails fast with guidance instead of waiting for interactive input when a previous install already exists
- `setup-github-repo.sh` now emits install examples that run `install.sh` from a temporary full repo checkout instead of a raw single-file script or the final install directory, and the README now documents the same constraint

### Fixed
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

# Changelog

All notable changes to AI Office Landing Skill will be documented in this file.

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

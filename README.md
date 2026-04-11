# AI Office Landing Skill - v2.3

<div align="center">

[![Version](https://img.shields.io/badge/version-v2.3.0-blue.svg)](https://github.com/anthropics/claude-code)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skill-orange.svg)](https://github.com/anthropics/claude-code)

AI-powered landing page generator with multi-agent orchestration, cost tracking, and dynamic skill discovery (Claude Code Skill)

[Installation](#installation) • [Features](#features) • [Usage](#usage) • [Contributing](CONTRIBUTING.md)

</div>

## 🚀 Quick Start

```bash
# Install the skill
cd ~/.claude/skills
git clone https://github.com/your-username/ai-office-landing-skill.git ai-office-landing
cd ai-office-landing
./install.sh

# Start using
claude
/landing
```

## ✨ Features

### v2.3 New Features 🎉
* **Phase 3.5 Orchestrator** - Automatic work integration and summary generation
* **Dynamic Skill Discovery** - Designer auto-finds relevant skills
* **Cross-Agent Consistency Checks** - Automated conflict detection
* **Progress Dashboard** - Visual execution status
* **Benchmark Analysis** - Compare with reference websites
* **Cost Tracking** - Real-time token usage monitoring

### Multi-Agent Workflow
1. **Phase 0-1**: Interview & brief generation
2. **Phase 2**: Style tokens & task creation
3. **Phase 3**: Parallel execution (Copy, Design, Frontend, SEO)
4. **Phase 3.5**: Orchestrator auto-summary ⭐ **NEW**
5. **Phase 4**: Critic review with benchmark analysis
6. **Phase 5**: Delivery

## 📊 Usage

```bash
# Basic usage
/landing

# Serial execution (spread across days)
/landing --serial

# Human critic review (cost-saving)
/landing --human

# Resume from checkpoint
/landing --resume

# Test skill discovery
~/.claude/skills/ai-office-landing/discover-skills.sh auto-designer

# Run orchestrator
~/.claude/skills/ai-office-landing/orchestrator.sh
```

## 📦 Installation

### Option 1: Direct Download
cd ~/.claude/skills && curl -fsSL https://github.com/your-username/ai-office-landing-skill/archive/refs/heads/main.tar.gz | tar -xz && mv ai-office-landing-skill-main ai-office-landing && cd ai-office-landing && ./install.sh

### Option 2: Git Clone
```bash
cd ~/.claude/skills
git clone https://github.com/your-username/ai-office-landing-skill.git ai-office-landing
cd ai-office-landing
./install.sh
```

### Option 3: CURL + Install
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/your-username/ai-office-landing-skill/main/install.sh)"
```

## 🏗️ Architecture

```
~/.claude/skills/ai-office-landing/
├── .claude-plugin/
│   ├── manifest.json       # Skill metadata
│   └── hooks.json         # Automation hooks
├── prompts/               # Agent prompts
│   ├── interviewer.md
│   ├── designer.md
│   ├── frontend.md
│   ├── seo.md
│   ├── critic.md
│   ├── benchmark-analyzer.md
│   └── orchestrator-summary.md
├── templates/            # Template files
├── install.sh           # Installation script
├── cost-tracker.sh      # Token cost tracking
├── discover-skills.sh   # Dynamic skill discovery ⭐ NEW
├── orchestrator.sh      # Phase 3.5 orchestrator ⭐ NEW
├── state-management.sh  # State persistence
├── README.md           # This file
├── CONTRIBUTING.md     # Contribution guidelines
├── LICENSE            # MIT License
└── ...
```

## 📊 Performance & Cost

**Estimated Token Usage:**
- Phase 0: 15,000 tokens
- Phase 1: 13,000 tokens
- Phase 2: 8,000 tokens
- Phase 3: 80,000 tokens (4 Executors)
- Phase 3.5: 5,000 tokens ⭐ NEW
- Phase 4: 20,000 tokens (Enhanced with Benchmark Analyzer)
- Phase 5: 5,000 tokens
- **Total**: ~146,000 tokens

**Optimization Tips:**
- Use `--serial` to spread across multiple days
- Use `--human` to skip automated Critic (cost-saving)
- Enable cost-saving mode: `export COST_SAVING_MODE=true`

## 🎯 Example Workflow

```bash
# 1. Phase 0-2: Interview and brief generation
/landing

# 2. Phase 3: Execution (Designer auto-discovers skills)
# Runs: discover-skills.sh auto-designer automatically

# 3. Phase 3.5: Auto-integration (automatically triggered)
orchestrator.sh

# 4. Phase 4: Critic review with benchmark analysis
# Enhanced with benchmark-analyzer.md

# 5. Phase 5: Delivery
# All outputs in ai-office/outputs/
```

## 🛠️ Advanced Features

### Skill Discovery
```bash
# Auto-discover for Designer
~/.claude/skills/ai-office-landing/discover-skills.sh auto-designer

# Search by keyword
~/.claude/skills/ai-office-landing/discover-skills.sh discover "color"

# Suggest based on task
~/.claude/skills/ai-office-landing/discover-skills.sh suggest "coffee shop landing page"
```

### Custom Orchestrator Checks
Edit `orchestrator.sh` to add:
- Custom consistency checks
- New conflict detection logic
- Additional project metrics

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Code guidelines
- Testing requirements
- Pull request process

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the Claude Code community
- Built with Claude Code Agent SDK
- Thanks to all contributors and testers

## 🔗 Links

- [Claude Code](https://claude.ai/code) - Official documentation
- [Anthropic AI](https://anthropic.com) - Creators of Claude
- [GitHub Issues](https://github.com/your-username/ai-office-landing-skill/issues) - Bug reports and feature requests

---

**Enjoy using AI Office Landing!** 🚀

<div align="center">

Made with ❤️ using Claude Code

</div>

# Contributing to AI Office Landing

Thank you for your interest in contributing to AI Office Landing! This document provides guidelines and instructions for contributing.

## 🚀 Quick Start

1. **Fork the repository** on GitHub
2. **Clone your fork**:
   ```bash
   git clone https://github.com/your-username/ai-office-landing-skill.git
   cd ai-office-landing-skill
   ```

3. **Install the skill for development**:
   ```bash
   ./install.sh install
   ```
   For unattended or repeat local installs, use `./install.sh install --force` to skip the overwrite prompt.

4. **Test the skill**:
   ```bash
   cd examples
   ./test.sh
   ```

## 📋 Development Guidelines

### Code Style

- **Shell scripts**: Use Bash 4+ features when possible (but maintain macOS compatibility)
- **Indentation**: 4 spaces for bash scripts
- **Naming**: Use descriptive function names with underscores
- **Comments**: Explain "why", not "what"

### Adding New Features

1. **Discuss first**: Open an issue to discuss major changes
2. **Keep it modular**: Each script should do one thing well
3. **Maintain backward compatibility**: Don't break existing functionality
4. **Test on multiple platforms**: macOS and Linux

### Project Structure

```
.
├── .claude-plugin/          # Plugin metadata
│   ├── manifest.json        # Skill definition
│   └── hooks.json          # Automation hooks
├── prompts/                 # Agent prompts
│   ├── interviewer.md
│   ├── designer.md
│   ├── frontend.md
│   ├── seo.md
│   ├── critic.md
│   ├── benchmark-analyzer.md
│   └── orchestrator-summary.md
├── templates/              # Template files
├── adapters/               # Model adapters
├── examples/               # Example usage
├── install.sh              # Installation script
├── cost-tracker.sh         # Token cost tracking
├── discover-skills.sh      # Skill discovery
├── orchestrator.sh         # Phase 3.5 orchestrator
├── state-management.sh     # State persistence
├── SKILL.md               # Main skill definition
├── README.md              # User documentation
├── CONTRIBUTING.md        # This file
└── LICENSE                # MIT License
```

## 🧪 Testing

### Manual Testing

Test your changes with real Claude Code:

```bash
# Start Claude Code
claude

# Run the skill
/landing

# Test specific features
/landing --serial
/landing --human
```

### Automated Testing

While we don't have a full test suite yet, you can test individual components:

```bash
# Test cost tracking
./cost-tracker.sh display_cost_header

# Test skill discovery
./discover-skills.sh help
./discover-skills.sh auto-designer

# Test orchestrator (requires ai-office/outputs/)
./orchestrator.sh
```

## 📦 Creating a Release

1. **Update version numbers**:
   - `manifest.json`
   - `install.sh`
   - `README.md`
   - `SKILL.md`

2. **Test thoroughly**: Run through complete workflow

3. **Update CHANGELOG**: Document new features and fixes

4. **Create PR**: Submit pull request with description

5. **Tag release**: Once merged, create a GitHub release

## 📝 Submitting Changes

### Pull Request Process

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**: Follow the development guidelines

3. **Commit with clear messages**:
   ```bash
   git commit -m "feat: add new skill discovery option"
   ```

4. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create Pull Request**:
   - Use clear title and description
   - Reference any related issues
   - Include testing steps

### Commit Message Format

We follow conventional commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `chore:` Build/config changes

Examples:
```
feat: add cost tracking dashboard
fix: resolve skill discovery on macOS
docs: update installation instructions
```

## 🐛 Reporting Issues

When reporting issues, please include:

1. **Environment**: OS, Bash version, Claude Code version
2. **Steps to reproduce**: Clear, numbered steps
3. **Expected behavior**: What should happen
4. **Actual behavior**: What actually happened
5. **Logs/error messages**: Any relevant output

## 💡 Feature Requests

We welcome feature requests! Please:

1. **Search existing issues**: Avoid duplicates
2. **Use feature request template**: If available
3. **Explain the use case**: Why is this feature needed?
4. **Suggest implementation**: How might it work?

## 🌐 Platform Support

We aim to support:

- **macOS**: Primary target (with Bash 3.2+)
- **Linux**: Full support
- **Windows (WSL)**: Best effort

When contributing, please test on at least one platform.

## 📚 Documentation

- Keep `README.md` user-focused
- Add technical details to `SKILL.MD`
- Document new prompts in `prompts/` with comments
- Update installation steps if needed

## 🤝 Community

- **Be respectful**: Follow the Code of Conduct
- **Help others**: Answer questions in issues
- **Share examples**: Show how you use the skill
- **Give feedback**: Help improve the project

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Acknowledgments

Thank you to all contributors who help make AI Office Landing better!

---

**Need help?** Open an issue or start a discussion on GitHub!

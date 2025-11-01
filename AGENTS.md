# Agent Instructions for Testing Casks and Formulas

This document provides guidelines for testing Homebrew casks and formulas in this tap.

## Quick Start

All changes must be committed and pushed to git before testing. The tap is configured to pull from the remote repository.

### Basic Workflow

1. **Make changes** to formula or cask files
2. **Commit to git**: `git add <files> && git commit -m "description"`
3. **Push to remote**: `git push origin main`
4. **Test installation** from the tap
5. **Verify functionality**

## Testing Formulas and Casks

### 1. Code Quality Checks (BEFORE Committing)

These checks run automatically via git pre-commit hook, but you can run manually:

```bash
# Check for style violations (runs automatically on commit)
brew style Formula/bluefin-cli.rb
brew style Casks/wallpaper-name.rb

# Auto-fix style issues
brew style --fix Formula/bluefin-cli.rb

# Full audit (includes deprecations, dependencies, etc)
# ⚠️ NOTE: Run AFTER pushing to remote, not before commit
brew audit --strict hanthor/tap/bluefin-cli
brew audit --strict hanthor/tap/wallpaper-name
```

### 2. Git Workflow (with Auto-Style Checking)

The pre-commit hook automatically runs `brew style` on all changed .rb files:

```bash
# Stage changes
git add Formula/bluefin-cli.rb

# Commit (pre-commit hook will check brew style)
git commit -m "Update bluefin-cli formula"
# ✓ If style checks pass, commit succeeds
# ✗ If style checks fail, commit is blocked - fix with: brew style --fix <file>

# Push to remote
git push origin main

# ✅ IMPORTANT: Run brew audit AFTER push
brew audit --strict hanthor/tap/bluefin-cli
```

### 3. Install from Tap (AFTER Pushing)

After pushing changes to git:

```bash
# Clean install (if already installed)
brew uninstall hanthor/tap/<formula-name> -f
rm -rf /home/linuxbrew/.linuxbrew/Cellar/<formula-name>*

# Install from tap (uses remote git repo)
brew install hanthor/tap/<formula-name>

# Build from source (ignores cached bottles)
brew install --build-from-source hanthor/tap/<formula-name>
```

### 4. Verify Installation

After installation, verify the expected files exist:

```bash
# Check binaries
which bluefin-cli
ls -la /home/linuxbrew/.linuxbrew/bin/bluefin-cli

# Check libexec
ls -la /home/linuxbrew/.linuxbrew/opt/<formula-name>/libexec/

# Check share
ls -la /home/linuxbrew/.linuxbrew/share/<formula-name>/

# Run post-install hooks (if needed)
brew postinstall hanthor/tap/<formula-name>
```

## Working with Remote Source Code

To inspect what files are actually being installed from remote repositories:

### Clone Remote Repos into hack/

```bash
# Clone source repos to inspect them
cd hack/packages
git clone https://github.com/ublue-os/packages.git
cd packages

# Explore the structure
ls -la packages/bluefin/
ls -la packages/ublue-bling/src/
ls -la packages/ublue-motd/
```

### View Source Files Before Installation

```bash
# View bling scripts
cat hack/packages/packages/ublue-bling/src/bling.sh
cat hack/packages/packages/ublue-bling/src/bling.fish

# View CLI logos
ls -la hack/packages/packages/bluefin/cli-logos/
ls -la hack/packages/packages/bluefin/cli-logos/logos/

# View fastfetch config
cat hack/packages/packages/bluefin/fastfetch/fastfetch.jsonc

# View RPM spec files for reference
cat hack/packages/packages/ublue-bling/ublue-bling.spec
cat hack/packages/packages/ublue-motd/ublue-motd.spec
cat hack/packages/packages/bluefin-schemas/bluefin-schemas.spec
```

## Formula-Specific Testing

### bluefin-cli

```bash
# Install
brew install --build-from-source hanthor/tap/bluefin-cli

# Verify scripts installed
test -f /home/linuxbrew/.linuxbrew/opt/bluefin-cli/libexec/bling/bling.sh && echo "✓ bling.sh installed"
test -f /home/linuxbrew/.linuxbrew/opt/bluefin-cli/libexec/bling/bling.fish && echo "✓ bling.fish installed"

# Check shell configs updated (should be in ~/.bashrc, ~/.zshrc, ~/.config/fish/config.fish)
grep "bluefin-cli bling" ~/.bashrc 2>/dev/null && echo "✓ Bash configured"
grep "bluefin-cli bling" ~/.zshrc 2>/dev/null && echo "✓ Zsh configured"
grep "bluefin-cli bling" ~/.config/fish/config.fish 2>/dev/null && echo "✓ Fish configured"

# Check optional dependencies
brew list eza 2>/dev/null && echo "✓ eza installed"
brew list starship 2>/dev/null && echo "✓ starship installed"
```

### Wallpaper Casks (aurora, bazzite, bluefin-wallpapers, etc.)

```bash
# Install
brew install --build-from-source hanthor/tap/bluefin-wallpapers

# Verify wallpapers installed
ls -la /home/linuxbrew/.linuxbrew/share/pixmaps/bluefin-wallpapers/
ls -la /home/linuxbrew/.linuxbrew/share/backgrounds/

# Check concurrent conversion worked (should see PNG files for your desktop)
file /home/linuxbrew/.linuxbrew/share/pixmaps/bluefin-wallpapers/*.png | head -5
```

### bluefin-motd

```bash
# Install
brew install --build-from-source hanthor/tap/bluefin-motd

# Run the motd
/home/linuxbrew/.linuxbrew/opt/bluefin-motd/bin/bluefin-motd

# Check caveats
brew info hanthor/tap/bluefin-motd
```

### bluefin-schemas (GNOME-only)

```bash
# Install (will fail gracefully on non-GNOME systems)
brew install --build-from-source hanthor/tap/bluefin-schemas

# On GNOME systems, verify dconf settings
dconf list /com/github/ublue-os/bluefin/
```

## Git Workflow

### Standard Commit Process

```bash
# Stage changes
git add Formula/bluefin-cli.rb

# Check what will be committed
git status

# Commit with descriptive message
git commit -m "Update bluefin-cli to support fish shell integration"

# Push to remote
git push origin main

# Wait for remote to update, then test
brew install --build-from-source hanthor/tap/bluefin-cli
```

### Viewing Recent Commits

```bash
# See last 5 commits
git log --oneline -5

# See changes in last commit
git show HEAD

# See what's different from remote
git log --oneline origin/main..main
```

## Troubleshooting

### Formula installation fails with "No such file or directory"

This usually means the formula is trying to write files incorrectly. Check:

```bash
# Look at the error carefully
brew install --build-from-source hanthor/tap/bluefin-cli 2>&1 | tail -50

# Read the formula to understand the install block
cat Formula/bluefin-cli.rb | grep -A 30 "def install"
```

### Cached bottles not using latest changes

Force a build from source:

```bash
# Clear cache
rm -rf /home/linuxbrew/.linuxbrew/Cellar/<formula-name>*

# Build from source
brew install --build-from-source hanthor/tap/<formula-name>
```

### Source files not found during build

Make sure the source directory structure in buildpath matches the URL:

```bash
# Check what gets extracted
brew install --build-from-source --verbose hanthor/tap/<formula-name> 2>&1 | grep -A 5 "buildpath"

# The buildpath should contain the tar's contents
# If URL is github-2025-10-28-01-29-41.tar.gz, it should extract to packages/
```

## Important Notes

- **Always push before testing**: The Homebrew tap pulls from the remote git repository
- **Pre-commit hook enforces brew style**: All commits automatically check style compliance
- **Run brew audit after each push**: The workflow is commit → push → audit → install
- **Use --build-from-source**: When testing formulas, always use this flag to avoid cached bottles
- **Check both audit and style**: Style is formatting, audit is functionality
- **Document failures**: If a formula fails, save the full error output
- **Keep hack/ in sync**: Periodically update cloned repos in hack/ to see latest source code

## Pre-Commit Hook Setup

The repository includes a pre-commit hook that automatically checks `brew style` on all changed Ruby files:

```bash
# The hook is located at:
.git/hooks/pre-commit

# It runs automatically when you commit
# If style check fails, commit is blocked until issues are fixed
# Fix with: brew style --fix <file>

# To manually run the hook:
.git/hooks/pre-commit
```

## Complete Development Workflow

1. Make changes to `.rb` files
2. `git add <files>` (stage your changes)
3. `git commit -m "description"` (pre-commit hook runs automatically)
4. If brew style fails: `brew style --fix <file>` and commit again
5. `git push origin main` (push to remote)
6. `brew audit --strict hanthor/tap/<formula-name>` (audit after push)
7. `brew install --build-from-source hanthor/tap/<formula-name>` (test install)
8. Verify all files are present and functionality works

## References

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Homebrew Cask Documentation](https://docs.brew.sh/Cask-Cookbook)
- [ublue-os packages repository](https://github.com/ublue-os/packages)

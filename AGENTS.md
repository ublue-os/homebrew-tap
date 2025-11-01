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

### 1. Install from Tap

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

### 2. Code Quality Checks

Before committing, always run these checks:

```bash
# Check for style violations
brew style Formula/bluefin-cli.rb
brew style Casks/wallpaper-name.rb

# Full audit (includes deprecations, dependencies, etc)
brew audit --strict Formula/bluefin-cli.rb
brew audit --strict Casks/wallpaper-name.rb

# Test the formula/cask
brew test hanthor/tap/<formula-name>
```

### 3. Verify Installation

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
- **Use --build-from-source**: When testing formulas, always use this flag to avoid cached bottles
- **Check both audit and style**: Style is formatting, audit is functionality
- **Document failures**: If a formula fails, save the full error output
- **Keep hack/ in sync**: Periodically update cloned repos in hack/ to see latest source code

## References

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Homebrew Cask Documentation](https://docs.brew.sh/Cask-Cookbook)
- [ublue-os packages repository](https://github.com/ublue-os/packages)

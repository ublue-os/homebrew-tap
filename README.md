# Universal Blue Homebrew Tap

This is a _staging area_ to test Linux casks builds of things we want. It is intended to show that homebrew casks on linux work great. This repository's metric of success is when the applications in here are deleted. This also ships artwork and OEM tools that are better managed in userspace than on an image.

Homebrew has asked us to run this as a tap as opposed to PRing these into individual projects, and that will take some work so in the meantime we can test.

## This is useful for

IDEs like Jetbrains and VSCode. They don't run well out of flatpaks so we put them on their own images. This lets the user also opt-into vscode instead of having it on a -dx image even if you don't use it.

### Installing

Add `Homebrew` `tap` first:

```shell
brew tap ublue-os/tap
```

Install apps in the `tap` with:

```shell
brew install --cask 1password-gui-linux
brew install --cask framework-tool
brew install --cask jetbrains-toolbox-linux
brew install --cask lm-studio-linux
brew install --cask positron-linux
brew install --cask visual-studio-code-linux
brew install --cask vscodium-linux
brew install asusctl

brew install --cask aurora-wallpapers
brew install --cask bazzite-wallpapers
brew install --cask bluefin-wallpapers
brew install --cask bluefin-wallpapers-extra
brew install --cask framework-wallpapers
```

### Uninstalling

Remove or uninstall apps with:

```shell
brew uninstall --cask 1password-gui-linux
brew uninstall --cask framework-tool
brew uninstall --cask jetbrains-toolbox-linux
brew uninstall --cask lm-studio-linux
brew uninstall --cask positron-linux
brew uninstall --cask visual-studio-code-linux
brew uninstall --cask vscodium-linux
brew uninstall asusctl

brew uninstall --cask aurora-wallpapers
brew uninstall --cask bazzite-wallpapers
brew uninstall --cask bluefin-wallpapers
brew uninstall --cask bluefin-wallpapers-extra
brew uninstall --cask framework-wallpapers
```

Remove the `Homebrew` `tap` with:

```shell
brew untap ublue-os/tap
```

## Includes

- [1Password](https://1password.com) - Password manager
- [ASUSCTL](https://asus-linux.org) - Control daemon and CLI tools for ASUS ROG laptops
- [Framework System Tool](https://github.com/FrameworkComputer/framework-system) - Hardware management for Framework laptops
- [JetBrains Toolbox](https://www.jetbrains.com/toolbox-app/) - JetBrains tools manager
- [LM Studio](https://lmstudio.ai/) - Local LLM discovery, download, and runtime
- [Positron](https://positron.posit.co/) - Data Science IDE for Python and R
- [Visual Studio Code](https://code.visualstudio.com) - Microsoft's code editor
- [VSCodium](https://vscodium.com) - Open-source build of VS Code

### Wallpapers

Metadata for GNOME is usually there.

If you are on KDE then [follow these instructions](https://github.com/renner0e/bluefin-wallpapers-plasma).

- Bluefin Wallpapers - Wallpapers for Bluefin
- Bluefin Extra Wallpapers - Additional wallpapers for Bluefin
- Aurora Wallpapers - Art made for Aurora
- Bazzite Wallpapers - Wallpapers made for Bazzite
- Framework Wallpapers

## Scope

- IDEs and other apps that aren't flatpak friendly
- Crucial apps for Aurora, Bazzite, and Bluefin that are appimages that need to be converted
- Command line tools for OEMs, framework, etc. so that we don't need to bake them into images
- Anything that helps us delete code in justfiles and other scripts

## Out of Scope

- Browsers
- GUI apps, every effort to use flatpak should be exhausted, or are out of our control (eg. vscode)
- General requests for common apps. We don't expect users to use this repo directly, the packages are there for us to automate in the background, ideall they never know this tap exists.


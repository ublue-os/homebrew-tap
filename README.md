# Universal Blue Homebrew Tap

This is a _staging area_ to test Linux casks builds of things we want. It is intended to show that homebrew casks on linux work great. This repository's metric of success is when the applications in here are deleted. This also ships artwork and OEM tools that are better managed in userspace than on an image.

Homebrew has asked us to run this as a tap as opposed to PRing these into individual projects, and that will take some work so in the meantime we can test.

### Experimental Tap

We have some in-progress, but not quite finished formulas and casks in an [experimental tap](https://github.com/ublue-os/experimental-tap). If you wish to experiment or provide feedback, check it out. Please send pull requests first, this is the production tap! 

## This is useful for

IDEs like Jetbrains and VSCode. They don't run well out of flatpaks so we put them on their own images. This lets the user also opt-into vscode instead of having it on a -dx image even if you don't use it.

```shell
brew tap ublue-os/tap
brew install --cask visual-studio-code-linux
brew install --cask vscodium-linux
brew install --cask jetbrains-toolbox-linux
brew install --cask lm-studio-linux
brew install --cask 1password-gui-linux
brew install --cask framework-tool

brew install --cask bluefin-wallpapers
brew install --cask bluefin-wallpapers-extra
brew install --cask aurora-wallpapers
brew install --cask bazzite-wallpapers
brew install --cask framework-wallpapers
```

## Includes

- 1Password - Password manager
- JetBrains Toolbox - JetBrains tools manager
- LM Studio - Local LLM discovery, download, and runtime
- Visual Studio Code - Microsoft's code editor
- VSCodium - Open-source build of VS Code
- Framework System Tool - Hardware management for Framework laptops

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


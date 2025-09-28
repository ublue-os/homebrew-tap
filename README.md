# Universal Blue Homebrew Tap

This is a _staging area_ to test Linux casks builds of things we want. It is intended to show that homebrew casks on linux work great. This repository's metric of success is when the applications in here are deleted. This also ships artwork and OEM tools that are better managed in userspace than on an image.

Homebrew has asked us to run this as a tap as opposed to PRing these into individual projects, and that will take some work so in the meantime we can test.

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
brew install --cask aurora-wallpapers
brew install --cask bluefin-wallpapers-plasma-dynamic
brew install --cask bazzite-wallpapers
brew install asusctl
```
## Includes

- 1Password - Password manager
- ASUSCTL - Control daemon and CLI tools for ASUS ROG laptops
- Bluefin Wallpapers - Additional wallpapers for Bluefin
- [Bluefin Wallpapers Plasma Dynamic](https://github.com/renner0e/bluefin-wallpapers-plasma) - utilizes [this KDE Plasma Plugin](https://github.com/zzag/plasma5-wallpapers-dynamic)
- Aurora Wallpapers - Commissioned art for Aurora
- Bazzite Wallpapers - Wallpapers made for Bazzite
- Framework System Tool - Hardware management for Framework laptops
- JetBrains Toolbox - JetBrains tools manager
- LM Studio - Local LLM discovery, download, and runtime
- Visual Studio Code - Microsoft's code editor
- VSCodium - Open-source build of VS Code

## Scope

- IDEs and other apps that aren't flatpak friendly
- Crucial apps for Aurora, Bazzite, and Bluefin that are appimages that need to be converted
- Command line tools for OEMs, framework, etc. so that we don't need to bake them into images
- Anything that helps us delete code in justfiles and other scripts

## Out of Scope

- Browsers
- GUI apps, every effort to use flatpak should be exhausted, or are out of our control (eg. vscode)
- General requests for common apps. We don't expect users to use this repo directly, the packages are there for us to automate in the background, ideall they never know this tap exists.


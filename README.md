# Universal Blue Homebrew Tap

This is a _staging area_ to test Linux casks builds of things we want. It is intended to show that homebrew casks on linux work great. This repository's metric of success is when it is deleted.

Homebrew has asked us to run this as a tap as opposed to PRing these into individual projects, and that will take some work so in the meantime we can test.

## This is useful for

IDEs like Jetbrains and VSCode. They don't run well out of flatpaks so we put them on their own images. This lets the user also opt-into vscode instead of having it on a -dx image even if you don't use it.

```shell
brew tap ublue-os/tap
brew install --cask jetbrains-toolbox-linux
brew install --cask lm-studio-linux
brew install --cask visual-studio-code-linux
```
## Includes

- Jetbrains Toolbox
- LM Studio
- Visual Studio Code

## Out of Scope

Browsers, etc. This is mostly for IDEs and things that help us remove the need for -dx images.

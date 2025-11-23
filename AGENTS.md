# AGENTS.md

This file provides an overview of the Universal Blue Homebrew Tap for an AI agent.

## Project Overview

This repository is a Homebrew tap for Universal Blue, a Linux distribution. It serves as a staging area for Linux casks and formulas that are not yet available in the main Homebrew repositories. The goal is to test and refine these packages before they are submitted to the official repositories.

The repository contains casks for GUI applications and formulas for command-line tools. The focus is on:

*   IDEs and other applications that do not work well as Flatpaks.
*   Tools and utilities for the Universal Blue ecosystem.
*   OEM tools, such as the Framework System Tool.
*   Artwork and wallpapers.

## How to Use

To use this tap, you first need to tap the repository:

```shell
brew tap ublue-os/tap
```

Then, you can install packages using the `brew install` command. For casks, you need to use the `--cask` flag.

### Examples

**Formulas:**

```shell
brew install heic-to-dynamic-gnome-wallpaper
```

**Casks:**

```shell
brew install --cask visual-studio-code-linux
brew install --cask vscodium-linux
brew install --cask jetbrains-toolbox-linux
```

## Repository Structure

*   `Casks/`: Contains the cask definitions for GUI applications.
*   `Formula/`: Contains the formula definitions for command-line tools.
*   `README.md`: Provides an overview of the project and instructions for users.
*   `.github/workflows/`: Contains GitHub Actions workflows for testing and publishing packages.

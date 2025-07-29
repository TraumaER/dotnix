# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a fresh Git repository named "dotnix" with no commits yet. The repository appears to be intended for Nix configuration management (dotfiles with Nix), but currently contains no source files.

## Development Setup

Since this is an empty repository, standard development commands are not yet established. Once Nix files are added, typical commands would include:

- `nix-build` - Build Nix expressions
- `nix develop` or `nix-shell` - Enter development environment
- `nixos-rebuild switch` - Apply NixOS configuration changes (if this becomes a NixOS config)
- `home-manager switch` - Apply Home Manager configuration (if this becomes a Home Manager config)

## Architecture

The repository structure is not yet established. For a typical Nix dotfiles repository, expect:

- `flake.nix` - Main Nix flake definition
- `configuration.nix` - System configuration
- `home.nix` - Home Manager configuration
- Module directories for organizing configurations

## Git Status

- Repository is initialized but has no commits
- Default branch: main
- No files are currently tracked
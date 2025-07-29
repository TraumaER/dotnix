# Dotnix - Cross-Platform Nix Configuration

A minimal, cross-platform Nix configuration using home-manager and nix-darwin that works on macOS (ARM), Linux, and WSL.

## Structure

```
├── flake.nix              # Main flake definition
├── home/                  # Home Manager configurations
│   ├── shared.nix         # Shared configuration across platforms
│   ├── darwin.nix         # macOS-specific configuration
│   ├── linux.nix          # Linux-specific configuration
│   └── wsl.nix            # WSL-specific configuration
├── modules/               # Reusable modules
│   ├── homebrew.nix       # Homebrew integration
│   └── keychain.nix       # Funtoo Keychain configuration
└── system/                # System-level configurations
    ├── darwin.nix         # nix-darwin system configuration
    └── settings.nix       # System settings scaffolding
```

## Platform Support

- **macOS (ARM only)**: Uses nix-darwin + home-manager with Homebrew support
- **Linux**: Uses home-manager with Homebrew and Keychain support
- **WSL**: Terminal-focused configuration with Keychain support

## Quick Start

### Prerequisites

Install Nix with flakes enabled:
```bash
# Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Or enable flakes on existing Nix installation
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### First-Time Setup

Since home-manager won't be available on the first run, use nix to run it:

#### macOS (System + Home Manager)
```bash
# First time - build and switch system configuration (includes home-manager)
nix run nix-darwin -- switch --flake .#darwin-system

# Or just Home Manager for first time
nix run home-manager/master -- switch --flake .#user@darwin

# Subsequent runs (after home-manager is installed)
darwin-rebuild switch --flake .#darwin-system
home-manager switch --flake .#user@darwin
```

#### Linux
```bash
# First time
nix run home-manager/master -- switch --flake .#user@linux

# Subsequent runs
home-manager switch --flake .#user@linux
```

#### WSL
```bash
# First time
nix run home-manager/master -- switch --flake .#user@wsl

# Subsequent runs
home-manager switch --flake .#user@wsl
```

### Development Shell
```bash
nix develop
```

## Configuration

### User Information
Update the username and home directory in each platform configuration:
- `home/darwin.nix`
- `home/linux.nix` 
- `home/wsl.nix`

### Adding Packages
Add packages to `home/shared.nix` for cross-platform packages, or to platform-specific files.

### Homebrew
Homebrew is automatically installed and configured for macOS and Linux. Add packages to the system configuration or use the homebrew module options.

### Keychain (Linux/WSL)
Funtoo Keychain is configured for SSH key management on Linux and WSL. Configure keys in the keychain module options.

### System Settings
System settings are provided as scaffolding in `system/settings.nix` but are commented out by default. Uncomment and modify as needed.

## Features

- ✅ Cross-platform support (macOS ARM, Linux, WSL)
- ✅ Shared configuration with platform-specific overrides
- ✅ Homebrew integration for macOS and Linux
- ✅ Funtoo Keychain for SSH key management (Linux/WSL)
- ✅ System settings scaffolding without automatic application
- ✅ Terminal-focused WSL configuration
- ✅ Modern Home Manager configuration patterns

## Notes

- macOS Intel support is intentionally excluded
- System settings are scaffolded but not applied by default
- WSL configuration focuses on terminal applications only
- All configurations use modern Home Manager patterns (no deprecated options)
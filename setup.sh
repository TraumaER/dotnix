#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "darwin"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -q Microsoft /proc/version 2>/dev/null; then
            echo "wsl"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Nix
install_nix() {
    if command_exists nix; then
        log_success "Nix is already installed"
        return 0
    fi

    log_info "Installing Nix..."
    
    # Use the Determinate Systems installer for better macOS support
    if command_exists curl; then
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate
    else
        log_error "curl is required to install Nix"
        return 1
    fi
    
    # Source nix
    if [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
        source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    fi
    
    log_success "Nix installed successfully"
}

# Install Homebrew
install_homebrew() {
    local os=$1
    
    case $os in
        "darwin")
            if [[ -x "/opt/homebrew/bin/brew" ]]; then
                log_success "Homebrew is already installed"
                return 0
            fi
            ;;
        "linux"|"wsl")
            if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
                log_success "Homebrew is already installed"
                return 0
            fi
            ;;
    esac

    log_info "Installing Homebrew..."
    
    if command_exists curl; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log_error "curl is required to install Homebrew"
        return 1
    fi
    
    # Add homebrew to PATH for this session
    case $os in
        "darwin")
            if [[ -x "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            ;;
        "linux"|"wsl")
            if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
                eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            fi
            ;;
    esac
    
    log_success "Homebrew installed successfully"
}

# Install Linux prerequisites
install_linux_prereqs() {
    log_info "Installing Linux prerequisites for Homebrew..."
    
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y build-essential procps curl file git
    elif command_exists yum; then
        sudo yum groupinstall -y 'Development Tools'
        sudo yum install -y procps-ng curl file git
    elif command_exists pacman; then
        sudo pacman -S --needed base-devel procps-ng curl file git
    else
        log_warning "Unknown package manager. Please install build tools manually."
    fi
}

# Main setup function
main() {
    log_info "Starting dotnix setup..."
    
    local os
    os=$(detect_os)
    log_info "Detected OS: $os"
    
    case $os in
        "darwin")
            log_info "Setting up macOS environment..."
            
            # Check for Xcode Command Line Tools
            if ! xcode-select -p &>/dev/null; then
                log_info "Installing Xcode Command Line Tools..."
                xcode-select --install
                log_warning "Please complete the Xcode Command Line Tools installation and run this script again."
                exit 1
            fi
            
            install_nix
            install_homebrew "$os"
            ;;
            
        "linux")
            log_info "Setting up Linux environment..."
            install_linux_prereqs
            install_nix
            install_homebrew "$os"
            ;;
            
        "wsl")
            log_info "Setting up WSL environment..."
            install_linux_prereqs
            install_nix
            install_homebrew "$os"
            ;;
            
        "unknown")
            log_error "Unsupported operating system: $OSTYPE"
            exit 1
            ;;
    esac
    
    # Enable nix-command and flakes
    log_info "Enabling Nix flakes and nix-command..."
    mkdir -p ~/.config/nix
    cat > ~/.config/nix/nix.conf << EOF
experimental-features = nix-command flakes
EOF
    
    log_success "Setup completed successfully!"
    log_info ""
    log_info "Next steps:"
    case $os in
        "darwin")
            log_info "1. Run: sudo darwin-rebuild switch --flake ~/.config/dotnix#holodeck"
            ;;
        "linux")
            log_info "1. Run: home-manager switch --flake ~/.config/dotnix#riker"
            ;;
        "wsl")
            log_info "1. Run: home-manager switch --flake ~/.config/dotnix#crusher"
            ;;
    esac
    log_info "2. Restart your shell or source your shell configuration"
}

# Run main function
main "$@"
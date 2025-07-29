{ config, pkgs, lib, ... }:

{
  # System configuration for macOS (ARM only)
  
  # Enable nix-darwin
  services.nix-daemon.enable = true;
  
  # System packages
  environment.systemPackages = with pkgs; [
    # System-level packages
  ];

  # Homebrew configuration
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;  # Don't auto-update to avoid system changes
      upgrade = false;     # Don't auto-upgrade to avoid system changes
      cleanup = "none";    # Don't cleanup to avoid system changes
    };
    
    # Taps (repositories)
    taps = [
      "homebrew/core"
      "homebrew/cask"
    ];
    
    # Formulae (command-line tools)
    brews = [
      # Add homebrew packages here
    ];
    
    # Casks (GUI applications)
    casks = [
      # Add GUI applications here
    ];
  };

  # System settings scaffolding (not applied by default)
  system.defaults = {
    # Dock settings (commented out to avoid applying)
    # dock = {
    #   autohide = true;
    #   orientation = "bottom";
    # };
    
    # Finder settings (commented out to avoid applying)
    # finder = {
    #   AppleShowAllExtensions = true;
    #   ShowPathbar = true;
    # };
    
    # System UI settings (commented out to avoid applying)
    # NSGlobalDomain = {
    #   AppleInterfaceStyle = "Dark";
    #   AppleShowAllExtensions = true;
    # };
  };
  
  # Fonts
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      # Add fonts here
    ];
  };

  # System version (required for nix-darwin)
  system.stateVersion = 4;
}
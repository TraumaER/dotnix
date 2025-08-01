{
  config,
  pkgs,
  lib,
  ...
}: {
  # System configuration for macOS
  system.primaryUser = "bannach";

  # Nix configuration
  nix.enable = false;

  # System packages
  environment.systemPackages = with pkgs; [
    # Essential system utilities needed for activation
    curl
  ];

  # Homebrew configuration
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    # Taps (repositories)
    taps = [];

    # Formulae (command-line tools)
    brews = [
      # Add homebrew packages here
      "awscli"
      "sevenzip" # 7-zip
      "nvm"
      
      # Docker container runtimes (CLI tools managed by nixpkgs in shared.nix)
      "colima" # Lightweight Docker runtime alternative
    ];

    # Casks (GUI applications)
    casks = [
      # Add GUI applications here
      
      # Docker container runtimes
      "orbstack" # Native macOS Docker Desktop alternative with GUI
    ];

    # Mac App Store apps
    masApps = {
      # Example: "Xcode" = 497799835;
    };
  };

  # Docker Configuration Notes:
  # - Docker CLI tools (docker, docker-compose) are managed by nixpkgs in shared.nix
  # - OrbStack and Colima provide container runtime backends
  # - Both tools can coexist and be switched using Docker contexts:
  #   
  #   Switch to OrbStack: docker context use orbstack
  #   Switch to Colima:   docker context use colima
  #   List contexts:      docker context ls
  #   
  # - OrbStack: Native macOS GUI + CLI, superior performance, commercial license
  # - Colima: CLI-only, good performance, completely free and open-source
  #
  # Usage:
  # 1. Start OrbStack via GUI or: open -a OrbStack
  # 2. Start Colima via CLI: colima start
  # 3. Switch contexts as needed for different projects or testing

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

  # System version (required for nix-darwin)
  system.stateVersion = 6;
}

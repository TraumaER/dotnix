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
    ];

    # Casks (GUI applications)
    casks = [
      # Add GUI applications here
    ];

    # Mac App Store apps
    masApps = {
      # Example: "Xcode" = 497799835;
    };
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

  # System version (required for nix-darwin)
  system.stateVersion = 6;
}

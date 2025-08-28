{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./shared.nix
    ../modules/homebrew.nix
    ../modules/keychain.nix
  ];

  # Linux-specific packages
  home.packages = with pkgs; [
    # GUI applications for Linux
    firefox

    # Linux-specific tools
    xclip
    wl-clipboard
  ];

  # Linux-specific program configurations
  programs = {
    # Platform-specific programs
    bash.shellAliases = {
      rebuild = "home-manager switch --flake ~/.config/dotnix#riker";
    };
    zsh.shellAliases = {
      rebuild = "home-manager switch --flake ~/.config/dotnix#riker";
    };
  };

  # Enable homebrew for Linux
  homebrew.enable = true;

  # Enable keychain for Linux
  keychain.enable = true;

  # Linux-specific environment variables
  home.sessionVariables = {
    # Add Linux-specific variables
  };

  # User information (adjust as needed)
  home = {
    username = "traumaer";
    homeDirectory = "/home/traumaer";
  };
}

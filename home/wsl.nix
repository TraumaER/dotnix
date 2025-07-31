{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./shared.nix
    ../modules/keychain.nix
  ];

  # WSL-specific packages (terminal apps only)
  home.packages = with pkgs; [
    # Terminal-focused tools for WSL
    openssh
    gnupg
  ];

  # WSL-specific program configurations
  programs = {
    # Platform-specific programs
  };

  # Enable keychain for WSL
  keychain.enable = true;

  # WSL-specific environment variables
  home.sessionVariables = {
    # WSL-specific variables
    BROWSER = "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe";
  };

  # User information (adjust as needed)
  home = {
    username = "traumaer";
    homeDirectory = "/home/traumaer";
  };
}

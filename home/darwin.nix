{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./shared.nix
    ../modules/homebrew.nix
  ];

  # macOS-specific packages
  home.packages = with pkgs; [
    # macOS-specific tools
  ];

  # macOS-specific program configurations
  programs = {
    # Platform-specific programs
    git = {
      userEmail = "113929542+abannachGrafana@users.noreply.github.com";
      signing.key = "08797C39E0828DC6";
      signing.signByDefault = true;
    };
  };

  # Enable homebrew for macOS
  homebrew.enable = true;

  # macOS-specific environment variables
  home.sessionVariables = {
    # Add macOS-specific variables
  };

  # User information
  home = {
    username = "bannach";
    homeDirectory = lib.mkForce "/Users/bannach";
  };
}

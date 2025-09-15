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
    gpg.enable = true;
  };
  services = {
    gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-curses;
      defaultCacheTtl = 34560000;
      maxCacheTtl = 34560000;
    };
  };

  # Enable homebrew for Linux
  homebrew.enable = true;

  # Enable keychain for Linux
  keychain = {
    enable = true;
    keys = ["id_ed25519" "F46A524D943277BD"];
  };

  # Linux-specific environment variables
  home.sessionVariables = {
    # Add Linux-specific variables
  };

  # User information (adjust as needed)
  home = {
    username = "bannach";
    homeDirectory = "/home/bannach";
  };
}

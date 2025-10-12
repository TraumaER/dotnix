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
    ../modules/nvm.nix
  ];

  # Linux-specific packages
  home.packages = with pkgs; [
    # GUI applications for Linux

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
    zsh = {
      shellAliases = {
        rebuild = "home-manager switch --flake ~/.config/dotnix#riker";
      };
    };
    gpg.enable = true;
    git.signing.signByDefault = false;
    git.signing.key = "C34C1E16C99F5810";
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
  homebrew = {
    enable = true;
    brews = [
    ];
    casks = [];
  };

  # Enable keychain for Linux
  keychain = {
    enable = false;
    keys = ["id_ed25519" "C34C1E16C99F5810"];
  };

  nvm.enable = true;

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

{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./shared.nix
    ../modules/homebrew.nix
    ../modules/nvm.nix
    ../modules/ssh-agent-relay.nix
  ];

  # Linux-specific packages
  home.packages = with pkgs; [
    # GUI applications for Linux
    firefox

    # Networking
    socat

    # Linux-specific tools
    xclip
    wl-clipboard
  ];

  # Linux-specific program configurations
  programs = {
    # Platform-specific programs
    bash.shellAliases = {
      rebuild = "home-manager switch --flake ~/.config/dotnix#worf";
    };
    zsh = {
      shellAliases = {
        rebuild = "home-manager switch --flake ~/.config/dotnix#worf";
      };
    };
    gpg.enable = true;
    git = {
      signing.format = "ssh";
      signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkhuppayEplrShbSTxxiuYXmylEGuqZqw/PlqTVs6d+";
    };
    ssh = {
      enable = true;
      matchBlocks = {
        "impala" = {
          host = "impala"; # becomes: Host impala
          hostname = "impala.lan"; # HostName impala.lan
          user = "traumaer";
        };
        "castiel" = {
          host = "castiel"; # becomes: Host impala
          hostname = "castiel.lan"; # HostName impala.lan
          user = "traumaer";
        };
        "menofletters" = {
          host = "menofletters"; # becomes: Host impala
          hostname = "menofletters.lan"; # HostName impala.lan
          user = "traumaer";
        };
        "bobby" = {
          host = "bobby"; # becomes: Host impala
          hostname = "bobby.lan"; # HostName impala.lan
          user = "traumaer";
        };
        "bunker" = {
          host = "bunker"; # becomes: Host impala
          hostname = "bunker.lan"; # HostName impala.lan
          user = "traumaer";
        };
        "chuck" = {
          host = "chuck";
          hostname = "chuck.lan";
          user = "bannach";
        };
      };
    };
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
    brews = [];
    casks = [];
  };

  nvm.enable = true;

  # Enable SSH agent relay for Bitwarden on WSL
  ssh-agent-relay = {
    enable = true;
    npiperelayPath = "/mnt/c/Users/Adam/scoop/shims/npiperelay.exe";
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

{
  config,
  pkgs,
  lib,
  ...
}: {
  # Shared packages across all platforms
  home.packages = with pkgs; [
    # Terminal utilities
    gnupg
    git
    gh # GitHub CLI
    curl
    wget
    tree
    htop
    neofetch
    ripgrep
    fd
    bat
    eza
    fzf
    tmux

    # Development tools
    vim
    neovim
    docker
    docker-compose
    alejandra # Nix formatter
  ];

  # Shared program configurations
  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      # Configure git settings here
      userName = lib.mkDefault "Adam Bannach";
      userEmail = lib.mkDefault "4845159+TraumaER@users.noreply.github.com";

      signing.format = lib.mkDefault "openpgp";
      signing.signByDefault = lib.mkDefault true;

      extraConfig = {
        url = {
          "git@github.com:" = {
            insteadOf = "https://github.com/";
          };
        };
      };
    };

    bash = {
      enable = true;
      shellAliases = {
        ll = "eza -alF";
        la = "eza -A";
        l = "eza -CF";
        grep = "grep --color=auto";
      };
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ll = "eza -alF";
        la = "eza -A";
        l = "eza -CF";
        grep = "grep --color=auto";
      };
    };

    starship = {
      enable = true;
      settings = {
        add_newline = false;
        format = "$all$character";
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  # Shared services
  services = {
    # Add shared services here
  };

  # Home Manager configuration
  home.stateVersion = "25.05";
}

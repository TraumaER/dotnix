{ config, pkgs, lib, ... }:

{
  # Shared packages across all platforms
  home.packages = with pkgs; [
    # Terminal utilities
    git
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
  ];

  # Shared program configurations
  programs = {
    home-manager.enable = true;
    
    git = {
      enable = true;
      # Configure git settings here
    };
    
    bash = {
      enable = true;
      shellAliases = {
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";
        grep = "grep --color=auto";
      };
    };
    
    zsh = {
      enable = true;
      enableCompletion = true;
      enableAutosuggestions = true;
      enableSyntaxHighlighting = true;
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
  home.stateVersion = "23.11";
}
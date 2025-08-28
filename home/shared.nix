{
  config,
  pkgs,
  lib,
  ...
}: {
  # Shared packages across all platforms
  home.packages = with pkgs; [
    # Nerd Fonts
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-mono

    # Terminal utilities
    alejandra # Nix formatter
    bat
    curl

    # Docker stuff
    docker
    docker-compose
    kind
    kubectl
    kubectx
    k9s

    # IAC
    tenv # OpenTofu/Terraform/Terragrunt/Atmos version manager
    (google-cloud-sdk.withExtraComponents (
      with google-cloud-sdk.components; [
        gke-gcloud-auth-plugin
      ]
    ))
    azure-cli

    # Version control
    gh # GitHub CLI
    git
    pre-commit
    zizmor

    actionlint
    eza # ls on steroids
    fd
    fzf
    fx
    gnupg
    go
    go-jsonnet
    golangci-lint
    mage
    htop
    neofetch
    neovim
    ripgrep
    shellcheck
    shfmt
    tmux
    tldr
    tree
    vim
    wget
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
      sessionVariables = {
        GOPROXY = "http://localhost:3000,direct";
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
        initYarn = "corepack enable && corepack install --global yarn@latest";
      };
      sessionVariables = {
        GOPROXY = "http://localhost:3100,direct";
      };
    };

    starship = {
      enable = true;
      settings = lib.importTOML ./starship-nerd-font-symbols.toml;
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

  # Athens Go module proxy docker-compose setup
  # Create docker-compose.yml for Athens proxy
  # Note: You'll need to manually create ~/.local/athens/.netrc with credentials for private repositories
  # Example .netrc format:
  # machine github.com
  # login your-username
  # password your-token
  home.file.".local/athens/docker-compose.yml".text = ''
    name: Athens Go Proxy
    services:
      athens:
        image: gomods/athens:latest
        container_name: athens_go_proxy
        ports:
          - "3100:3000"
        volumes:
          - athens_storage:/var/lib/athens
          - ./.netrc:/etc/.netrc:ro
        environment:
          - ATHENS_STORAGE_TYPE=disk
          - ATHENS_DISK_STORAGE_ROOT=/var/lib/athens
          - ATHENS_TIMEOUT=300
          - ATHENS_NETRC_PATH=/etc/.netrc
        restart: unless-stopped
    volumes:
      athens_storage:
        driver: local
  '';

  # Home Manager configuration
  home.stateVersion = "25.05";
}

{
  config,
  pkgs,
  lib,
  ...
}: {
  # Shared packages across all platforms
  home.packages = with pkgs; [
    # Shell configuration

    # Nerd Fonts
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-mono

    # Terminal utilities
    alejandra # Nix formatter
    bat
    curl
    posting

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
    pay-respects
    ripgrep
    rustup
    rustscan
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
      signing.key = lib.mkDefault "F46A524D943277BD";

      extraConfig = {
        init = {
          defaultBranch = "main";
        };
        url = {
          "git@github.com:" = {
            insteadOf = "https://github.com/";
          };
        };
      };
      aliases = {
        # https://fortes.com/2022/make-git-better-with-fzf/
        addm = "!git ls-files --deleted --modified --other --exclude-standard | fzf -0 -m --preview 'git diff --color=always {-1}' | xargs -r git add";
        addmp = "!git ls-files --deleted --modified --exclude-standard | fzf -0 -m --preview 'git diff --color=always {-1}' | xargs -r -o git add -p";
        cb = "!git branch --all | grep -v '^[*+]' | awk '{print $1}' | fzf -0 --preview 'git show --color=always {-1}' | sed 's/remotes\\/origin\\///g' | xargs -r git checkout";
        cs = "!git stash list | fzf -0 --preview 'git show --pretty=oneline --color=always --patch \"$(echo {} | cut -d: -f1)\"' | cut -d: -f1 | xargs -r git stash pop";
        db = "!git branch | grep -v '^[*+]' | awk '{print $1}' | fzf -0 --multi --preview 'git show --color=always {-1}' | xargs -r git branch --delete";
        Db = "!git branch | grep -v '^[*+]' | awk '{print $1}' | fzf -0 --multi --preview 'git show --color=always {-1}' | xargs -r git branch --delete --force";
        ds = "!git stash list | fzf -0 --preview 'git show --pretty=oneline --color=always --patch \"$(echo {} | cut -d: -f1)\"' | cut -d: -f1 | xargs -r git stash drop";
        edit = "!git ls-files --modified --other --exclude-standard | sort -u | fzf -0 --multi --preview 'git diff --color {}' | xargs -r $EDITOR -p";
        fixup = "!git log --oneline --no-decorate --no-merges | fzf -0 --preview 'git show --color=always --format=oneline {1}' | awk '{print $1}' | xargs -r git commit --fixup";
        resetm = "!git diff --name-only --cached | fzf -0 -m --preview 'git diff --color=always {-1}' | xargs -r git reset";
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
        GOPROXY = "http://localhost:3100,direct";
      };
      profileExtra = ''
        if [ -t 1 ] && [ "$SHELL" != "$(command -v zsh)" ]; then
          exec zsh
        fi
      '';
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
      oh-my-zsh = {
        enable = true;
        plugins = [
          "brew"
          "git"
          "kubectl"
          "debian"
          "npm"
          "nvm"
          "colored-man-pages"
          "colorize"
          "pip"
          "python"
          "gh"
        ];
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    pay-respects = {
      enable = true;
      enableZshIntegration = true;
    };

    starship = {
      enable = true;
      settings = lib.importTOML ./starship-bracketed-segments.toml;
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

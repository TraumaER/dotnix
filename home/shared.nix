{
  config,
  pkgs,
  lib,
  ...
}: let
  # Common eza flags
  ezaFlags = "--icons=auto --classify=auto --color=auto";

  # Common shell aliases shared between bash and zsh
  commonShellAliases = {
    ll = "eza ${ezaFlags} -aal";
    la = "eza ${ezaFlags} -aa";
    ls = "eza ${ezaFlags}";
    tree = "eza ${ezaFlags} -I '.git' -a --tree";
    grep = "grep --color=auto";
    rebuild = "dotnix rebuild";
  };

  # Common shell functions shared between bash and zsh
  commonShellFunctions = ''
    # Fuzzy-select a git worktree and cd into it
    wt() {
      local dir
      dir=$(git worktree list --porcelain |
        awk '/^worktree / { sub(/^worktree /, ""); print }' |
        fzf)

      [[ -n "$dir" ]] && cd "$dir"
    }
  '';
in {
  imports = [
    ../modules/options.nix
    ../modules/features.nix
    ../modules/homebrew.nix
    ../modules/keychain.nix
    ../modules/nvm.nix
    ../modules/neovim.nix
  ];

  home.packages = with pkgs; [
    nerd-fonts.hack
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-mono
    alejandra
    bat
    curl
    gh
    git
    eza
    fd
    fzf
    fx
    gnupg
    htop
    fastfetch
    openssh
    pay-respects
    ripgrep
    tmux
    tldr
    tree
    vim
    wget
  ];
  fonts.fontconfig.enable = true;
  xdg.enable = true;

  # Shared program configurations
  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      settings = {
        core = {
          excludesFile = "${config.home.homeDirectory}/.gitignore_global";
        };
        init = {
          defaultBranch = "main";
        };
        alias = {
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
    };

    bash = {
      enable = true;
      shellAliases = commonShellAliases;
      initExtra = commonShellFunctions;

      profileExtra = ''
        if [ -t 1 ] && [ "$SHELL" != "$(command -v zsh)" ]; then
          exec zsh
        fi
      '';
    };

    zsh = {
      enable = true;
      dotDir = lib.mkDefault config.home.homeDirectory;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = commonShellAliases;
      initContent = commonShellFunctions;
      oh-my-zsh = {
        enable = true;
        plugins = ["git" "colored-man-pages" "colorize" "gh"];
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

  home.file.".gitignore_global".text = ''
    # Global gitignore patterns
    .DS_Store
    .idea/
    .vscode/
    node_modules/
    dist/
    build/
    target/
    *.log
    lefthook-local.yml
    CLAUDE.local.md
    settings.local.json
  '';

  # Home Manager configuration
  home.stateVersion = "25.05";
}

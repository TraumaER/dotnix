{
  config,
  pkgs,
  lib,
  ...
}: let
  allowedSigners = ./git-allowed-signers;
  allowedSignersPath = "${config.xdg.configHome}/git/allowed_signers";
in {
  imports = [
    ./shared.nix
    ../modules/homebrew.nix
  ];
  fonts.fontconfig.enable = true;
  # macOS-specific packages
  home.packages = with pkgs; [
    # macOS-specific tools
  ];

  # macOS-specific program configurations
  programs = {
    # SSH is managed by 1Password's ssh-agent, so this is disabled.
    ssh = {
      enable = false;
      matchBlocks."*" = {
        addKeysToAgent = "yes";
        extraOptions = {
          UseKeychain = "yes";
        };
      };
    };
    git = {
      settings = {
        user.email = "244587300+abannach-onebrief@users.noreply.github.com";
        gpg.ssh.allowedSignersFile = allowedSignersPath;
      };
      signing.format = "ssh";
      signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILEFX2ZiAHE1UWQ7f3AWylMJBH+bJXQEss6hxkb+QMPG";
      signing.signer = "ssh-keygen";
      signing.signByDefault = true;
    };
    bash.shellAliases = {
      rebuild = "home-manager switch --flake ~/.config/dotnix#picard";
      rebuildSys = "sudo darwin-rebuild switch --flake ~/.config/dotnix#holodeck";

      # Work aliases
    };
    zsh.initContent = ''
      bindkey "^[[3~" delete-char
    '';
    zsh.shellAliases = {
      rebuild = "home-manager switch --flake ~/.config/dotnix#picard";
      rebuildSys = "sudo darwin-rebuild switch --flake ~/.config/dotnix#holodeck";

      # Work aliases
    };
    zsh.sessionVariables = {
      NODE_EXTRA_CA_CERTS = "$HOME/.certs/zscaler_cert.pem";
      CURL_CA_BUNDLE = "$HOME/.certs/zscaler_cert.pem";
      CARGO_HTTP_CAINFO = "$HOME/.certs/zscaler_cert.pem";
      CLAUDE_CODE_TMPDIR = "/tmp/claude";
      MVM_NO_CHROME = 1;
      SANDBOX_INSTALL_SKIP_RC = 1;
      SANDBOX_INSTALL_AGENTS = "claude";
      SANDBOX_NO_AUTOUPDATE = 1;
      SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };
  };

  # Enable homebrew for macOS
  homebrew.enable = true;

  # macOS-specific environment variables
  home.sessionVariables = {
    # Add macOS-specific variables
  };

  home.sessionPath = [
    # Add macOS-specific PATH entries
    "$HOME/.local/bin"
    "$HOME/code/scripts"
  ];

  home.file.".wgetrc".text = ''
    ca_certificate=/Users/bannach/.certs/zscaler_cert.pem
  '';
  # Symlink gitconfig from XDG config home
  home.file.".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/git/config";

  home.activation.copyGitAllowedSigners = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$(dirname "${allowedSignersPath}")"
    install -m 0644 "${allowedSigners}" "${allowedSignersPath}"
  '';

  # User information
  home = {
    username = "bannach";
    homeDirectory = "/Users/bannach";
  };
}

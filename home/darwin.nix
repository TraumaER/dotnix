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
  fonts.fontconfig.enable = true;
  # macOS-specific packages
  home.packages = with pkgs; [
    # macOS-specific tools
  ];

  # macOS-specific program configurations
  programs = {
    ssh = {
      enable = true;
      addKeysToAgent = "yes";
      extraConfig = ''
        UseKeychain yes
      '';
    };
    git = {
      userEmail = "113929542+abannachGrafana@users.noreply.github.com";
      signing.key = "08797C39E0828DC6";
      signing.signByDefault = true;
    };
    bash.shellAliases = {
      rebuild = "sudo darwin-rebuild switch --flake ~/.config/dotnix#holodeck";

      # Work aliases
      sso-gcloud = "$HOME/code/repos/deployment_tools/scripts/sso/gcloud.sh reset";
      sso-aws = "$HOME/code/repos/deployment_tools/scripts/sso/aws.sh reset";
      sso-all = "sso-gcloud && sso-aws";
      # GCOM scripts
      gcom-dev = "$DTOOLS_SCRIPTS/gcom/gcom-dev";
      gcom-ops = "$DTOOLS_SCRIPTS/gcom/gcom-ops";
      gcom = "$DTOOLS_SCRIPTS/gcom/gcom";
      add-myself-to-org = "$DTOOLS_SCRIPTS/gcom/add-myself-to-org";
      remove-myself-from-org = "$DTOOLS_SCRIPTS/gcom/remove-myself-from-org";
      cleanup-my-orgs = "$DTOOLS_SCRIPTS/gcom/cleanup-my-orgs";
      # Vault scripts
      vault-get = "$DTOOLS_SCRIPTS/vault/vault-get";
      vault-put = "$DTOOLS_SCRIPTS/vault/vault-put";
      vault-patch = "$DTOOLS_SCRIPTS/vault/vault-patch";
      vault-list = "$DTOOLS_SCRIPTS/vault/vault-list";
      vault-token = "$DTOOLS_SCRIPTS/vault/vault-token";
      vault-shell = "$DTOOLS_SCRIPTS/vault/vault-shell";
    };
    zsh.initContent = ''
      bindkey "^[[3~" delete-char
    '';
    zsh.shellAliases = {
      rebuild = "sudo darwin-rebuild switch --flake ~/.config/dotnix#holodeck";

      # Work aliases
      sso-gcloud = "$HOME/code/repos/deployment_tools/scripts/sso/gcloud.sh reset";
      sso-aws = "$HOME/code/repos/deployment_tools/scripts/sso/aws.sh reset";
      sso-az = "$HOME/code/repos/deployment_tools/scripts/sso/az.sh reset";
      sso-all = "sso-gcloud && sso-aws && sso-az";
      # GCOM scripts
      gcom-dev = "$DTOOLS_SCRIPTS/gcom/gcom-dev";
      gcom-ops = "$DTOOLS_SCRIPTS/gcom/gcom-ops";
      gcom = "$DTOOLS_SCRIPTS/gcom/gcom";
      add-myself-to-org = "$DTOOLS_SCRIPTS/gcom/add-myself-to-org";
      remove-myself-from-org = "$DTOOLS_SCRIPTS/gcom/remove-myself-from-org";
      cleanup-my-orgs = "$DTOOLS_SCRIPTS/gcom/cleanup-my-orgs";
      # Vault scripts
      vault-get = "$DTOOLS_SCRIPTS/vault/vault-get";
      vault-put = "$DTOOLS_SCRIPTS/vault/vault-put";
      vault-patch = "$DTOOLS_SCRIPTS/vault/vault-patch";
      vault-list = "$DTOOLS_SCRIPTS/vault/vault-list";
      vault-token = "$DTOOLS_SCRIPTS/vault/vault-token";
      vault-shell = "$DTOOLS_SCRIPTS/vault/vault-shell";
    };
    zsh.sessionVariables = {
      GRAFANA_TEAM = "adaptive-telemetry";
      DTOOLS_SCRIPTS = "$HOME/code/repos/deployment_tools/scripts";
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
    homeDirectory = "/Users/bannach";
  };
}

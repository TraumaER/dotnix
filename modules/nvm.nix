{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.nvm;
  git = lib.getExe pkgs.git;
  ssh = lib.getExe pkgs.openssh;
  omzEnabled =
    (config.programs.zsh.enable or false)
    && (config.programs.zsh.oh-my-zsh.enable or false);
  zshNvm = pkgs.fetchFromGitHub {
    owner = "lukechilds";
    repo = "zsh-nvm";
    rev = "745291dcf20686ec421935f1c3f8f3a2918dd106";
    hash = "sha256-4O1a5bsNoqwB0hB8YU1fEVafsPQK8l7jr3GlF68ckZg=";
  };
in {
  options.nvm.enable = mkEnableOption "Node Version Manager (nvm) support";

  config = {
    # Fail fast if the option is enabled but Oh My Zsh is not
    assertions = [
      {
        assertion = !(cfg.enable && !omzEnabled);
        message = ''
          You enabled `nvm.enable = true`, but programs.zsh.oh-my-zsh is not enabled.
          Please enable Oh My Zsh (programs.zsh.oh-my-zsh.enable = true) to use this module.
        '';
      }
    ];

    # Make ZSH_CUSTOM a writable dir in your home (not the Nix store)
    home.sessionVariables.ZSH_CUSTOM = "${config.home.homeDirectory}/.oh-my-zsh/custom";

    # Symlink the plugin into the custom plugins dir
    home.file.".oh-my-zsh/custom/plugins/zsh-nvm".source = zshNvm;
    programs.zsh.oh-my-zsh.plugins =
      mkIf (cfg.enable && omzEnabled)
      (mkAfter ["zsh-nvm"]);
  };
}

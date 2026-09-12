{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.dotnix;
  brew = lib.escapeShellArg cfg.brew.executable;
  brewfile = pkgs.writeText "dotnix-Brewfile" (lib.concatMapStrings (p: "brew ${builtins.toJSON p}\n") cfg.brew.brews + lib.concatMapStrings (p: "cask ${builtins.toJSON p}\n") cfg.brew.casks);
  shell = ''
    if [[ -x ${brew} ]]; then
      eval "$(${brew} shellenv)"
    fi
  '';
in {
  config = lib.mkIf cfg.features.homebrew {
    home.activation.brewInstall = lib.mkIf (!cfg.integrated && (cfg.brew.brews != [] || cfg.brew.casks != [])) (lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [[ ! -x ${brew} ]]; then
        echo "Homebrew executable missing: "${brew} >&2
        exit 1
      fi
      run env HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_BUNDLE_NO_UPGRADE=1 ${brew} bundle install --no-upgrade --file=${brewfile}
    '');
    programs.bash.bashrcExtra = shell;
    programs.zsh.initContent = shell;
  };
}

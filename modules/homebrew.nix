{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.homebrew;
  brewPath =
    if pkgs.stdenv.isDarwin
    then "/opt/homebrew/bin/brew"
    else "/home/linuxbrew/.linuxbrew/bin/brew";
in {
  options.homebrew = {
    enable = mkEnableOption "homebrew support";

    packages = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of homebrew packages to install";
    };
  };

  config = mkIf cfg.enable {
    # Add homebrew to PATH
    home.sessionPath = mkIf (pkgs.stdenv.isLinux) [
      "/home/linuxbrew/.linuxbrew/bin"
    ];

    home.activation.brewInstall = lib.hm.dag.entryAfter ["writeBoundary"] ''
            if [ ${toString (length cfg.packages)} -gt 0 ]; then
              $DRY_RUN_CMD echo "Installing Homebrew packages..."
              $DRY_RUN_CMD cat > "Brewfile" << 'EOF'
      ${concatMapStrings (pkg: "brew \"${pkg}\"\n") cfg.packages}
      EOF
              $DRY_RUN_CMD ${brewPath} bundle --file="Brewfile"
              $DRY_RUN_CMD rm -f "Brewfile"
            fi
    '';

    # Shell integration using the modern approach
    programs.bash.bashrcExtra = mkIf cfg.enable ''
      if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      elif [[ "$OSTYPE" == "darwin"* ]] && [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
    '';

    programs.zsh.initContent = mkIf cfg.enable ''
      if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      elif [[ "$OSTYPE" == "darwin"* ]] && [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
    '';
  };
}

{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.homebrew;
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

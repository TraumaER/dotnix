{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.keychain;
in {
  options.keychain = {
    enable = mkEnableOption "Funtoo Keychain support";

    keys = mkOption {
      type = types.listOf types.str;
      default = ["id_rsa" "id_ed25519"];
      description = "List of SSH keys to load with keychain";
    };

    agents = mkOption {
      type = types.listOf (types.enum ["ssh" "gpg"]);
      default = ["ssh"];
      description = "List of agents to start (ssh, gpg)";
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = ["--quiet"];
      description = "Extra flags to pass to keychain";
    };
  };

  config = mkIf cfg.enable {
    # Install keychain package
    home.packages = with pkgs; [keychain];

    # Shell integration for bash
    programs.bash.bashrcExtra = ''
      # Keychain integration
      if command -v keychain &> /dev/null; then
        eval $(keychain ${concatStringsSep " " cfg.extraFlags} --eval ${concatMapStringsSep " " (agent: "--agents ${agent}") cfg.agents} ${concatStringsSep " " cfg.keys})
      fi
    '';

    # Shell integration for zsh
    programs.zsh.envExtra = ''
      # Keychain integration
      if command -v keychain &> /dev/null; then
        eval $(keychain ${concatStringsSep " " cfg.extraFlags} --eval ${concatMapStringsSep " " (agent: "--agents ${agent}") cfg.agents} ${concatStringsSep " " cfg.keys})
      fi
    '';

    # For fish shell users
    programs.fish.interactiveShellInit = mkIf config.programs.fish.enable ''
      # Keychain integration
      if command -v keychain > /dev/null
        eval (keychain ${concatStringsSep " " cfg.extraFlags} --eval ${concatMapStringsSep " " (agent: "--agents ${agent}") cfg.agents} ${concatStringsSep " " cfg.keys})
      end
    '';
  };
}

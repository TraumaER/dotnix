{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.ssh-agent-relay;
in {
  options.ssh-agent-relay = {
    enable = mkEnableOption "SSH agent forwarding from Windows to WSL using npiperelay and socat";

    socketPath = mkOption {
      type = types.str;
      default = "$HOME/.ssh/agent.sock";
      description = "Path to the Unix socket for SSH agent";
    };

    pipeName = mkOption {
      type = types.str;
      default = "//./pipe/openssh-ssh-agent";
      description = "Windows named pipe to forward (for Bitwarden, typically //./pipe/openssh-ssh-agent)";
    };

    npiperelayPath = mkOption {
      type = types.str;
      default = "npiperelay.exe";
      description = "Path to npiperelay.exe (should be in Windows PATH or provide full path)";
    };
  };

  config = mkIf cfg.enable {
    # Ensure socat is available (it's already in shared.nix but we can make it explicit here)
    home.packages = with pkgs; [socat];

    # Create the SSH agent relay script
    home.file.".local/bin/start-ssh-agent-relay.sh" = {
      text = ''
        #!/usr/bin/env bash
        # SSH Agent forwarding from Windows to WSL using npiperelay and socat

        export SSH_AUTH_SOCK="${cfg.socketPath}"

        # Check if the socket is already listening
        ss -a | grep -q "$SSH_AUTH_SOCK"
        if [ $? -ne 0 ]; then
            # Remove stale socket if it exists
            rm -f "$SSH_AUTH_SOCK"

            # Start socat relay in background
            (setsid socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork EXEC:"${cfg.npiperelayPath} -ei -s ${cfg.pipeName}",nofork &) >/dev/null 2>&1
        fi
      '';
      executable = true;
    };

    # Shell integration for bash
    programs.bash.initExtra = ''
      # SSH Agent relay setup
      if [[ -f "$HOME/.local/bin/start-ssh-agent-relay.sh" ]]; then
        source "$HOME/.local/bin/start-ssh-agent-relay.sh"
      fi
    '';

    # Shell integration for zsh
    programs.zsh.initContent = ''
      # SSH Agent relay setup
      if [[ -f "$HOME/.local/bin/start-ssh-agent-relay.sh" ]]; then
        source "$HOME/.local/bin/start-ssh-agent-relay.sh"
      fi
    '';

    # For fish shell users
    programs.fish.interactiveShellInit = mkIf config.programs.fish.enable ''
      # SSH Agent relay setup
      if test -f "$HOME/.local/bin/start-ssh-agent-relay.sh"
        source "$HOME/.local/bin/start-ssh-agent-relay.sh"
      end
    '';
  };
}

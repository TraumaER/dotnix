{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types mkEnableOption;
  string = default:
    mkOption {
      type = types.str;
      inherit default;
    };
  nullable = mkOption {
    type = types.nullOr types.str;
    default = null;
  };
in {
  options.dotnix = {
    features = lib.genAttrs ["development" "containers" "cloud" "desktop" "homebrew" "nvm" "keychain" "signing" "githubSsh" "onePassword" "java" "browser" "athens"] (name: mkEnableOption name);
    localDirectory = nullable;
    integrated = mkOption {
      type = types.bool;
      default = false;
      internal = true;
    };
    brew = {
      executable = string (
        if pkgs.stdenv.isDarwin
        then "/opt/homebrew/bin/brew"
        else "/home/linuxbrew/.linuxbrew/bin/brew"
      );
      brews = mkOption {
        type = types.listOf types.str;
        default = [];
      };
      casks = mkOption {
        type = types.listOf types.str;
        default = [];
      };
    };
    signing = {
      key = nullable;
      format = mkOption {
        type = types.enum ["ssh" "openpgp"];
        default = "ssh";
      };
      allowedSigners = mkOption {
        type = types.lines;
        default = "";
      };
    };
    onePasswordSocket = nullable;
    browser = nullable;
    jdk = nullable;
    athensImage = nullable;
  };
}

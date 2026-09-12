# Run the generated Brew activation with Home Manager's actual dry-run helper.
{
  pkgs,
  constructors,
  inputs,
  system,
}: let
  c =
    (constructors.mkHomeConfiguration {
      inherit system;
      platform =
        if pkgs.stdenv.isDarwin
        then "darwin"
        else "linux";
      account = {
        username = "example";
        homeDirectory = "/srv/example";
      };
      features.homebrew = true;
      settings.brew = {
        executable = "${brew}/bin/brew";
        brews = ["sevenzip"];
      };
    }).config;
  brew = pkgs.writeShellScriptBin "brew" ''
    echo invoked >> "$BREW_LOG"
    test "$HOMEBREW_NO_AUTO_UPDATE" = 1
    test "$HOMEBREW_NO_INSTALL_CLEANUP" = 1
    test "$HOMEBREW_BUNDLE_NO_UPGRADE" = 1
    test "$1" = bundle
    test "$2" = install
    test "$3" = --no-upgrade
    case "$4" in --file=/nix/store/*-dotnix-Brewfile) ;; *) exit 1 ;; esac
  '';
  activation = pkgs.writeText "brew-activation" c.home.activation.brewInstall.data;
in
  pkgs.runCommand "activation-safety" {nativeBuildInputs = [pkgs.bash];} ''
    export BREW_LOG="$TMPDIR/brew.log"
    echo 'existing caller Brewfile' > Brewfile
    echo 'existing signer data' > allowed_signers
    cp Brewfile original-Brewfile
    cp allowed_signers original-signers
    source ${inputs.home-manager}/lib/bash/home-manager.sh
    export DRY_RUN=1
    source ${activation}
    test ! -e "$BREW_LOG"
    cmp Brewfile original-Brewfile
    cmp allowed_signers original-signers
    unset DRY_RUN
    source ${activation}
    test "$(cat "$BREW_LOG")" = invoked
    cmp Brewfile original-Brewfile
    cmp allowed_signers original-signers
    touch "$out"
  ''

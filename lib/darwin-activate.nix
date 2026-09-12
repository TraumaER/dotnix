{pkgs}:
pkgs.writeShellApplication {
  name = "dotnix-darwin-activate";
  runtimeInputs = [pkgs.nix];
  text = ''
    if [[ $# != 1 || "$1" != /nix/store/* || ! -x "$1/sw/bin/darwin-rebuild" ]]; then
      echo 'Expected one built nix-darwin system store path' >&2
      exit 1
    fi
    nix-env --profile /nix/var/nix/profiles/system --set "$1"
    exec "$1/sw/bin/darwin-rebuild" activate
  '';
}

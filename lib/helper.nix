{pkgs}:
pkgs.writeShellApplication {
  name = "dotnix";
  runtimeInputs = [pkgs.python3 pkgs.nix pkgs.git];
  text = ''exec python3 ${../scripts/dotnix.py} "$@"'';
}

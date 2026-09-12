#!/usr/bin/env bash
set -euo pipefail
checkout=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# Reject unsupported hardware before downloading/installing anything. Explicit
# target overrides are validated by the generator as well.
host=$(uname -s)
arch=$(uname -m)
target=$host
next=''
for arg in "$@"; do
  if [[ "$next" == platform ]]; then target=$arg; next=''; continue; fi
  if [[ "$next" == arch ]]; then arch=$arg; next=''; continue; fi
  case "$arg" in
    --platform) next=platform ;;
    --platform=*) target=${arg#*=} ;;
    --arch) next=arch ;;
    --arch=*) arch=${arg#*=} ;;
  esac
done
case "$target/$arch" in
  Darwin/arm64|darwin/arm64|darwin/aarch64|Linux/x86_64|linux/x86_64|wsl/x86_64|linux/amd64|wsl/amd64) ;;
  *) echo "Unsupported target: $target/$arch" >&2; exit 1 ;;
esac
no_install=false
for arg in "$@"; do
  case "$arg" in --no-install|--help|-h) no_install=true ;; esac
done
if ! command -v nix >/dev/null 2>&1 && ! "$no_install"; then
  installer=$(mktemp)
  trap 'rm -f "$installer"' EXIT
  curl --proto '=https' --tlsv1.2 -fsSL https://install.determinate.systems/nix -o "$installer"
  sh "$installer" install --determinate --no-confirm
  if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
fi
if command -v python3 >/dev/null 2>&1; then
  exec python3 "$checkout/scripts/setup.py" --checkout "$checkout" "$@"
fi
if command -v nix >/dev/null 2>&1; then
  exec nix --extra-experimental-features 'nix-command flakes' run "$checkout#onboard" -- --checkout "$checkout" "$@"
fi
echo 'Python 3 is required for --no-install generation; install Python or rerun without --no-install.' >&2
exit 1

# Contributor guidance

This repository exports portable Home Manager/nix-darwin modules. Keep accounts, personal packages, keys, work environment and organization signers in generated local configurations. Never import ignored local files from shared Nix modules or use impure machine discovery in Nix.

- `flake.nix` exports modules, constructors, locked runners and evaluation checks.
- `lib/configurations.nix` propagates explicit account/platform records.
- `home/shared.nix` provides core; `modules/features.nix` gates optional packages/integrations.
- `scripts/setup.py` generates local files; `setup.sh` bootstraps prerequisites.
- `scripts/dotnix.py` refreshes only the source input, verifies locks and builds before activation.

Preserve state versions (Home Manager 25.05, Darwin 6). Respect unmanaged-file collisions and Home Manager's supported `run` activation helper. Brew activation has a single owner; do not enable cleanup or upgrades by default.

Run:

```sh
python3 -m unittest discover -s tests -v
shellcheck setup.sh scripts/dotnix
nix flake check --all-systems
```

`--no-build` is useful for evaluation on a single host. Checks assert all supported platform configurations and identity propagation. Native Linux/macOS CI builds generated Home Manager configurations; macOS also builds integrated Darwin. Keep evaluation, build, dry-run and real activation results distinct. Never activate a developer's configuration during validation.

Before Git-backed evaluation, add new intended source files with `git add`; Git flakes omit untracked files. For a restricted session that cannot update the index, validate a temporary Git checkout containing the intended files. Exclude ignored local migration artifacts from that checkout.

Dependency upgrades are explicit changes to the repository's flake.lock. Test local source refresh with a tracked edit and ensure nested dependency revisions remain identical. Exercise spaces in checkout/home/XDG paths, WSL markers, repeated setup, rebinding, feature disablement and existing-file collisions when changing onboarding or activation.

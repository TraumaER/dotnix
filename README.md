# Dotnix

Reusable Nix modules for Apple Silicon macOS and x86-64 Linux/WSL. Core provides Bash/Zsh, Git, Neovim, search/navigation tools, terminal utilities, and fonts. It has no Git identity, signing key, work account, SSH agent override, or Go proxy default.

## Onboarding

```sh
git clone <your-repository-url> /path/to/dotnix
cd /path/to/dotnix
./setup.sh
```

Setup installs Determinate Nix if Nix is absent, offers optional features, and generates `${XDG_CONFIG_HOME:-$HOME/.config}/dotnix-local`. It never activates the configuration. Existing Nix installations and daemon ownership are retained. Commands enable `nix-command` and `flakes` additively for their invocation; setup never rewrites `nix.conf`. Use a recent Nix with `flake update INPUT` and `allow-dirty-locks` support (Nix 2.24 or newer).

macOS defaults to standalone Home Manager. `--mode darwin` selects integrated nix-darwin/Home Manager. An existing Darwin system profile selects integrated mode automatically; existing generated configurations retain their mode. Linux/WSL use standalone Home Manager.

```sh
./setup.sh --non-interactive --enable development --enable containers
./scripts/dotnix doctor
./scripts/dotnix build
./scripts/dotnix rebuild
```

After activation, `dotnix` is on PATH and `rebuild` calls the helper. Integrated macOS also provides `rebuildSys`. Both aliases select the generated local directory. Use `dotnix --config '/custom/configuration path' rebuild` or set `DOTNIX_LOCAL` to select a different configuration. The helper builds before switching, and only Darwin switching runs through sudo. Home Manager collision checks stop activation on unmanaged files.

`./setup.sh --help` lists all flags. `--no-install` generates without installing prerequisites and requires Python 3. `--destination`, `--checkout`, `--username`, `--home`, `--config-home`, `--platform`, `--arch`, and `--brew-executable` override detection. Account home paths come from the account database, not an assumed `/home/USER` or `/Users/USER`. Paths containing spaces are supported. Unsupported targets are rejected before installation. Bootstrap uses Python 3 if present, otherwise the Python provided by the locked Nix setup package.

## Features and preferences

Each interactive feature has equivalent `--enable NAME` / `--disable NAME` flags. After generation, edit `preferences.json`; subsequent setup runs preserve it. Values in `settings` configure integrations.

| Feature | Contents / configuration |
| --- | --- |
| `development` | Go, Rust, Bun, mise, linters, build tools, HTTP tooling |
| `containers` | Docker/Compose and Kubernetes clients; provide your own runtime |
| `colima` | Colima runtime plus the `containers` tools, installed through Nix; start manually |
| `cloud` | AWS, Azure, Google Cloud, tenv |
| `desktop` | Linux Firefox and clipboard tools; macOS Kap and AltTab through Homebrew |
| `homebrew` | Brew integration; `settings.brew.brews` / `casks` select packages |
| `nvm` | Pinned zsh-nvm plugin; downloads Node/NVM on use |
| `keychain` | Keychain integration; set `keychain.keys` in `home.nix` |
| `signing` | Requires `--signing-key`; `--signing-format ssh` or `openpgp` |
| `githubSsh` | Rewrites GitHub HTTPS Git remotes to SSH |
| `onePassword` | Requires `--one-password-socket`; install and enable the external SSH agent |
| `java` | Requires `--jdk jdk21` (explicit nixpkgs JDK attribute) |
| `browser` | Requires `--browser '/absolute/path/to/browser'`; Windows browser launching is optional |
| `athens` | Requires `--athens-image gomods/athens:v0.15.0` or a digest |

Selecting macOS desktop apps during setup also enables Homebrew. Setting `desktop` manually on macOS requires `homebrew`. Custom Brew executables must exist and be executable (integrated Darwin requires `PREFIX/bin/brew`); otherwise the conventional `/opt/homebrew/bin/brew` or `/home/linuxbrew/.linuxbrew/bin/brew` is used. Homebrew and its platform prerequisites are installed only when selected. Unsupported Linux package managers receive manual prerequisite guidance.

Homebrew defaults to no cleanup, upgrade, or automatic update during activation. Its Brewfile lives in the Nix store; the caller's Brewfile is untouched. Standalone mode uses Home Manager activation, while integrated mode assigns Brew to nix-darwin. `settings.brew.executable` can override the machine-specific executable when needed. See the [nix-darwin Homebrew options](https://nix-darwin.github.io/nix-darwin/manual/#opt-homebrew.onActivation.cleanup).

Signing requires explicit configuration. Set `settings.signing.allowedSigners` to the signer file's text or use `xdg.configFile."git/allowed_signers"` in your local module. Home Manager's declarative file handling preserves collision detection. Keychain and 1Password are mutually exclusive agent selections. Without either feature, existing `SSH_AUTH_SOCK` is retained.

To use Colima as an alternate runtime, select `--enable colima` during initial setup. For an existing configuration, set `features.colima` to `true` in the local `preferences.json` and run `rebuild`. Then start it explicitly:

```sh
colima start --runtime docker
docker context use colima
docker info
```

Colima creates and activates its Docker context when started. Use `docker context ls` and `docker context use <name>` to switch to another runtime, and `colima stop` to stop its VM. Enabling the feature does not start the VM or change Docker contexts during activation. See the [Colima runtime documentation](https://colima.run/docs/runtimes/).

Athens requires a running Docker daemon (for example, Colima), Docker Compose, and a `.local/athens/.netrc` file under your home containing credentials for private repositories. Protect that file with mode 0600 and never put credentials into Nix expressions (the Nix store is readable). Start it explicitly:

```sh
cd ~/.local/athens
docker compose up -d
```

The proxy binds only to localhost. Enabling Athens sets the same `GOPROXY` in Bash and Zsh. Disabling it restores Go's normal behavior; setup does not start Docker or Athens.

## Local customization and moving machines

The local directory contains:

- `machine.json`: account, platform, deployment mode, checkout, XDG and Brew paths.
- `preferences.json`: portable feature selections and integration settings.
- `home.nix`: unrestricted Home Manager customizations.
- `darwin.nix`: unrestricted Darwin customizations.
- `flake.nix` / `flake.lock`: declared checkout input and reproducible dependency graph.

For example, put identity and work settings in local `home.nix`:

```nix
{pkgs, ...}: {
  programs.git.settings.user = {
    name = "Your Name";
    email = "you@example.org";
  };
  home.packages = [pkgs.jq];
  home.sessionVariables.PROJECT_ROOT = "/your/projects";
}
```

Repeated setup leaves existing files unchanged. After moving the checkout or copying the local configuration to another machine:

```sh
/path/to/new/checkout/setup.sh --reconfigure --destination '/path/to/dotnix-local'
```

Reconfiguration refreshes machine information and rebinds the declared source URL, retaining preferences and local modules, including local flake edits. Use `--mode home-manager` when moving an integrated Darwin configuration to Linux. Review platform-specific preferences (Brew casks, agent/browser paths) and local modules for the new host. Reconfiguration deliberately ignores feature flags; edit the retained preferences to change selections.

## Dependency updates and recovery

Before doctor/build/rebuild, the helper refreshes **only** the local `dotnix` input and verifies its upstream revisions against the checkout's `flake.lock`. Upstream updates belong in this repository:

```sh
nix flake update nixpkgs home-manager nix-darwin
```

Review and commit the resulting lock change. Local checkout edits are included through a declared `git+file` input; **new source files must be added with `git add`** before evaluation. Untracked and ignored files are excluded. Local dirty source locks are permitted by the helper so uncommitted tracked edits can be built; keep these machine-specific locks local. See [Nix input update semantics](https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake-update.html).

If the local lock conflicts with the checkout's dependency revisions, remove only the local `flake.lock` and rebuild. If activation reports existing shell/Git/signer files, back them up or merge their contents explicitly and retry; dotnix does not overwrite them or automatically create backup suffixes. Use an existing Home Manager generation's `activate` to roll back; integrated installations can use their locked `darwin-rebuild --rollback` runner. Build/evaluation success does not prove activation will succeed.

## Module API and contributing

`homeModules.default`, `.darwin`, `.linux`, `.wsl` and `darwinModules.default` are exported alongside:

```nix
dotnix.lib.mkHomeConfiguration {
  account = { username = "dev"; homeDirectory = "/srv/people/dev"; configHome = "/srv/preferences/dev"; };
  system = "x86_64-linux";
  platform = "wsl";
  features.development = true;
  settings = {};
  modules = [./home.nix];
}
```

`mkDarwinConfiguration` takes the same account/features/settings, Darwin `modules`, and `homeModulesExtra`. It derives the primary user, system account and Home Manager identity from that account. Compatibility state versions remain Home Manager `25.05` and Darwin `6`. The generated local outputs are `homeConfigurations.default` and, for integrated mode, `darwinConfigurations.default`. Packages export `home-manager`, `darwin-rebuild` (macOS), `dotnix`, and `onboard` from the same locked inputs.

`examples/darwin-settings.nix` is inactive documentation: copy desired settings into your local Darwin module. Contributor commands and verification expectations are in [CLAUDE.md](CLAUDE.md).

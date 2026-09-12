{
  system,
  constructors,
  inputs,
}: let
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  account = {
    username = "example";
    homeDirectory = "/srv/people/example home";
    configHome = "/srv/preferences/example";
  };
  home = platform: features: settings:
    constructors.mkHomeConfiguration {
      inherit account platform features settings;
      system =
        if platform == "darwin"
        then "aarch64-darwin"
        else "x86_64-linux";
    };
  cores = map (platform: (home platform {} {}).config) ["darwin" "linux" "wsl"];
  darwin = (constructors.mkDarwinConfiguration {inherit account;}).config;
  darwinBrew =
    (constructors.mkDarwinConfiguration {
      inherit account;
      features = {
        homebrew = true;
        desktop = true;
      };
      settings.brew = {
        executable = "/custom brew/bin/brew";
        brews = ["sevenzip"];
      };
    }).config;
  standaloneBrew =
    (home "darwin" {
        homebrew = true;
        signing = true;
        onePassword = true;
      } {
        brew = {
          executable = "/custom brew/bin/brew";
          brews = ["sevenzip"];
        };
        signing = {
          key = "synthetic";
          allowedSigners = "example ssh-ed25519 SYNTHETIC";
        };
        onePasswordSocket = "/custom agent/socket";
      }).config;
  enabled =
    (home "linux" {
        development = true;
        containers = true;
        cloud = true;
        desktop = true;
        homebrew = true;
        nvm = true;
        keychain = true;
        java = true;
        athens = true;
        signing = true;
        githubSsh = true;
        browser = true;
      } {
        jdk = "jdk21";
        athensImage = "gomods/athens:v0.15.0";
        signing.key = "synthetic-key";
        browser = "/opt/browser";
      }).config;
  checkCore = c:
    assert c.home.username == account.username;
    assert c.home.homeDirectory == account.homeDirectory;
    assert c.xdg.configHome == account.configHome;
    assert c.home.stateVersion == "25.05";
    assert c.programs.git.signing.signByDefault != true;
    assert !(c.programs.git.settings ? user);
    assert !(c.programs.git.settings ? url);
    assert c.programs.git.signing.key == null;
    assert !(c.home.sessionVariables ? SSH_AUTH_SOCK);
    assert !(c.home.sessionVariables ? GOPROXY);
    assert !(c.home.sessionVariables ? ZSH_CUSTOM);
    assert !(c.home.file ? ".oh-my-zsh/custom/plugins/zsh-nvm");
    assert !(c.home.file ? ".local/athens/docker-compose.yml");
    assert builtins.all (a: a.assertion) c.assertions;
      builtins.seq c.home.activationPackage.drvPath true;
  valid =
    builtins.all checkCore cores
    && darwin.system.primaryUser == account.username
    && darwin.users.users.${account.username}.home == account.homeDirectory
    && darwin.home-manager.users.${account.username}.home.homeDirectory == account.homeDirectory
    && darwin.system.stateVersion == 6
    && builtins.seq darwin.system.build.toplevel.drvPath true;
in {
  activation-safety = import ./activation.nix {inherit pkgs constructors inputs system;};
  brew-ownership = assert darwinBrew.homebrew.onActivation.cleanup == "none";
  assert !darwinBrew.homebrew.onActivation.autoUpdate;
  assert !darwinBrew.homebrew.onActivation.upgrade;
  assert darwinBrew.homebrew.prefix == "/custom brew";
  assert !(darwinBrew.home-manager.users.${account.username}.home.activation ? brewInstall);
  assert standaloneBrew.home.activation ? brewInstall;
  assert standaloneBrew.xdg.configFile."git/allowed_signers".text == "example ssh-ed25519 SYNTHETIC";
  assert standaloneBrew.home.sessionVariables.SSH_AUTH_SOCK == "/custom agent/socket";
    builtins.seq darwinBrew.system.build.toplevel.drvPath (pkgs.runCommand "brew-ownership" {} ''touch $out'');
  portable-evaluation = assert valid; pkgs.runCommand "portable-evaluation" {} ''touch $out'';
  features = assert enabled.programs.bash.sessionVariables.GOPROXY == enabled.programs.zsh.sessionVariables.GOPROXY;
  assert enabled.nvm.enable;
  assert enabled.programs.java.package == pkgs.jdk21 || system == "aarch64-darwin";
  assert builtins.all (a: a.assertion) enabled.assertions;
    builtins.seq enabled.home.activationPackage.drvPath (pkgs.runCommand "features-evaluation" {} ''touch $out'');
}

{
  config,
  account,
  lib,
  ...
}: let
  cfg = config.home-manager.users.${account.username}.dotnix;
in {
  assertions = [
    {
      assertion = !cfg.features.homebrew || lib.hasSuffix "/bin/brew" cfg.brew.executable;
      message = "Integrated Homebrew requires an executable at PREFIX/bin/brew";
    }
  ];
  system.primaryUser = account.username;
  users.users.${account.username}.home = account.homeDirectory;
  nix.enable = false;
  system.stateVersion = 6;
  homebrew = lib.mkIf cfg.features.homebrew {
    enable = true;
    prefix = builtins.dirOf (builtins.dirOf cfg.brew.executable);
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };
    global.autoUpdate = false;
    brews = cfg.brew.brews;
    casks = cfg.brew.casks;
  };
}

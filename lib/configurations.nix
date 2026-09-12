{inputs}: let
  inherit (inputs) nixpkgs home-manager nix-darwin;
  lib = nixpkgs.lib;
  validate = account: system: platform:
    assert lib.assertMsg (account.username != "" && lib.hasPrefix "/" account.homeDirectory) "An explicit username and absolute homeDirectory are required";
    assert lib.assertMsg ((platform == "darwin" && system == "aarch64-darwin") || (builtins.elem platform ["linux" "wsl"] && system == "x86_64-linux")) "Unsupported platform/system combination"; true;
  homeModules = {
    account,
    platform,
    features,
    settings,
    localDirectory,
    integrated,
  }: [
    ../home/${platform}.nix
    ({...}: {
      home.username = account.username;
      home.homeDirectory = account.homeDirectory;
      xdg.configHome = account.configHome or "${account.homeDirectory}/.config";
      dotnix = settings // {inherit features localDirectory integrated;};
    })
  ];
in rec {
  mkHomeConfiguration = {
    account,
    system,
    platform,
    features ? {},
    settings ? {},
    modules ? [],
    localDirectory ? null,
  }:
    assert validate account system platform;
      home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {inherit inputs;};
        modules =
          homeModules {
            inherit account platform features settings localDirectory;
            integrated = false;
          }
          ++ modules;
      };
  mkDarwinConfiguration = {
    account,
    system ? "aarch64-darwin",
    platform ? "darwin",
    features ? {},
    settings ? {},
    modules ? [],
    homeModulesExtra ? [],
    localDirectory ? null,
  }:
    assert validate account system platform;
    assert platform == "darwin";
      nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {inherit inputs account;};
        modules =
          [
            ../system/darwin.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {inherit inputs;};
              home-manager.users.${account.username}.imports =
                homeModules {
                  inherit account platform features settings localDirectory;
                  integrated = true;
                }
                ++ homeModulesExtra;
            }
          ]
          ++ modules;
      };
}

{
  description = "Portable Home Manager and nix-darwin modules";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
  }: let
    systems = ["aarch64-darwin" "x86_64-linux"];
    each = nixpkgs.lib.genAttrs systems;
    constructors = import ./lib/configurations.nix {inherit inputs;};
  in {
    lib = constructors;
    homeModules = {
      default = import ./home/shared.nix;
      darwin = import ./home/darwin.nix;
      linux = import ./home/linux.nix;
      wsl = import ./home/wsl.nix;
    };
    darwinModules.default = import ./system/darwin.nix;
    packages = each (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in
      {
        default = self.packages.${system}.dotnix;
        dotnix = import ./lib/helper.nix {inherit pkgs;};
        onboard = pkgs.writeShellApplication {
          name = "dotnix-setup";
          runtimeInputs = [pkgs.python3 pkgs.nix pkgs.git pkgs.curl];
          text = ''exec python3 ${./scripts/setup.py} "$@"'';
        };
        home-manager = home-manager.packages.${system}.home-manager;
      }
      // nixpkgs.lib.optionalAttrs (system == "aarch64-darwin") {
        darwin-activate = import ./lib/darwin-activate.nix {inherit pkgs;};
        darwin-rebuild = nix-darwin.packages.${system}.darwin-rebuild;
      });
    checks = each (system: import ./tests/evaluation.nix {inherit system constructors inputs;});
    devShells = each (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {packages = [pkgs.git pkgs.python3 pkgs.shellcheck pkgs.alejandra];};
    });
  };
}

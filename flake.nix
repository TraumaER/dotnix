{
  description = "Cross-platform Nix configuration with home-manager";

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

  outputs = { self, nixpkgs, home-manager, nix-darwin }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      
      forAllSystems = nixpkgs.lib.genAttrs systems;
      
      mkSystem = system: modules: 
        if nixpkgs.lib.hasSuffix "darwin" system
        then nix-darwin.lib.darwinSystem {
          inherit system modules;
          specialArgs = { inherit inputs; };
        }
        else nixpkgs.lib.nixosSystem {
          inherit system modules;
          specialArgs = { inherit inputs; };
        };
    in
    {
      # Home Manager configurations
      homeConfigurations = {
        # macOS (ARM)
        "user@darwin" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          modules = [
            ./home/darwin.nix
          ];
          extraSpecialArgs = { inherit inputs; };
        };
        
        # Linux
        "user@linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home/linux.nix
          ];
          extraSpecialArgs = { inherit inputs; };
        };
        
        # WSL
        "user@wsl" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home/wsl.nix
          ];
          extraSpecialArgs = { inherit inputs; };
        };
      };
      
      # System configurations
      darwinConfigurations = {
        "darwin-system" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./system/darwin.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.user = import ./home/darwin.nix;
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
          specialArgs = { inherit inputs; };
        };
      };
      
      # Development shell
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          buildInputs = with nixpkgs.legacyPackages.${system}; [
            nixos-rebuild
            home-manager
          ] ++ nixpkgs.lib.optionals (nixpkgs.lib.hasSuffix "darwin" system) [
            nix-darwin.packages.${system}.default
          ];
        };
      });
    };
}